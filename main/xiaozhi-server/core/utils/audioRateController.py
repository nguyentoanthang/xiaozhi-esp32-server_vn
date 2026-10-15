import time
import asyncio
from collections import deque
from config.logger import setup_logging

TAG = __name__
logger = setup_logging()


class AudioRateController:
    """
    Audio rate controller - precisely controls audio sending according to the 60ms frame duration
    Solves the accumulated timing error problem under high concurrency
    """

    def __init__(self, frame_duration=60, send_delay=0):
        """
        Args:
            frame_duration: duration of a single audio frame (milliseconds), default 60ms
            send_delay: custom send interval (milliseconds).
                        0 = send at the frame_duration pace;
                        >0 = send at the send_delay pace (main thread does not enqueue delay, no pre-buffering)
        """
        # Flow-control interval (milliseconds): use the configured value when send_delay > 0, otherwise frame_duration
        self.interval_ms = send_delay if send_delay > 0 else frame_duration
        self.queue = deque()
        self.play_position = 0  # virtual playback position (milliseconds)
        self.start_timestamp = None  # start timestamp (read-only, not modified)
        self.pending_send_task = None
        self.logger = logger
        self.queue_empty_event = asyncio.Event()  # queue-empty event
        self.queue_empty_event.set()  # initially empty
        self.queue_has_data_event = asyncio.Event()  # queue-has-data event
        self._last_queue_empty_time = 0  # last time the queue was emptied (seconds)

    def reset(self):
        """Reset the controller state"""
        if self.pending_send_task and not self.pending_send_task.done():
            self.pending_send_task.cancel()
            # After cancelling the task, it will be cleaned up on the next event loop iteration; no need to block and wait

        self.queue.clear()
        self.play_position = 0
        self.start_timestamp = None  # set by the first audio packet
        self._last_queue_empty_time = 0  # reset the time
        # Related event handling
        self.queue_empty_event.set()
        self.queue_has_data_event.clear()

    def add_audio(self, opus_packet):
        """Add an audio packet to the queue"""
        # If the queue was empty before, adjust the timestamp to keep the playback time continuous
        # This way, audio added while waiting for a tool call will not be played early
        # If the gap is short (<1 frame), it is normal streaming and no reset is needed
        if len(self.queue) == 0 and self.play_position > 0:
            elapsed_since_empty = (time.monotonic() - self._last_queue_empty_time) * 1000
            # Only when the gap exceeds the duration of 1 frame is it considered a real "pause and resume"
            if elapsed_since_empty >= self.interval_ms:
                self.start_timestamp = time.monotonic() - (self.play_position / 1000)
                self.logger.bind(tag=TAG).debug(
                    f"Queue resumed from empty, resetting timestamp, current playback position: {self.play_position}ms, gap: {elapsed_since_empty:.0f}ms"
                )

        self.queue.append(("audio", opus_packet))
        # Related event handling
        self.queue_empty_event.clear()
        self.queue_has_data_event.set()

    def add_message(self, message_callback):
        """
        Add a message to the queue (sent immediately, does not occupy playback time)

        Args:
            message_callback: message send callback async def()
        """
        if len(self.queue) == 0 and self.play_position > 0:
            elapsed_since_empty = (time.monotonic() - self._last_queue_empty_time) * 1000
            if elapsed_since_empty >= self.interval_ms:
                self.start_timestamp = time.monotonic() - (self.play_position / 1000)
                self.logger.bind(tag=TAG).debug(
                    f"Queue resumed from empty, resetting timestamp, current playback position: {self.play_position}ms, gap: {elapsed_since_empty:.0f}ms"
                )

        self.queue.append(("message", message_callback))
        # Related event handling
        self.queue_empty_event.clear()
        self.queue_has_data_event.set()

    def _get_elapsed_ms(self):
        """Get the elapsed time (milliseconds)"""
        if self.start_timestamp is None:
            return 0
        return (time.monotonic() - self.start_timestamp) * 1000

    async def check_queue(self, send_audio_callback):
        """
        Check the queue and send audio/messages on time

        Args:
            send_audio_callback: callback for sending audio async def(opus_packet)
        """
        while self.queue:
            item = self.queue[0]
            item_type = item[0]

            if item_type == "message":
                # Message type: send immediately, does not occupy playback time
                _, message_callback = item
                self.queue.popleft()
                try:
                    await message_callback()
                except Exception as e:
                    self.logger.bind(tag=TAG).error(f"Failed to send message: {e}")
                    raise

            elif item_type == "audio":
                if self.start_timestamp is None:
                    self.start_timestamp = time.monotonic()

                _, opus_packet = item

                # Loop and wait until the time is reached
                while True:
                    # Calculate the time difference
                    elapsed_ms = self._get_elapsed_ms()
                    output_ms = self.play_position

                    if elapsed_ms < output_ms:
                        # Not yet time to send, calculate the wait duration
                        wait_ms = output_ms - elapsed_ms

                        # Continue checking after waiting (may be interrupted)
                        try:
                            await asyncio.sleep(wait_ms / 1000)
                        except asyncio.CancelledError:
                            self.logger.bind(tag=TAG).debug("Audio sending task cancelled")
                            raise
                        # Re-check the time after waiting (loop back to while True)
                    else:
                        # Time reached, exit the wait loop
                        break

                # Time reached, remove from the queue and send
                self.queue.popleft()
                self.play_position += self.interval_ms
                try:
                    await send_audio_callback(opus_packet)
                except Exception as e:
                    self.logger.bind(tag=TAG).error(f"Failed to send audio: {e}")
                    raise

        # Clear the event after the queue is processed
        self.queue_empty_event.set()
        self.queue_has_data_event.clear()
        self._last_queue_empty_time = time.monotonic()  # record the time the queue was emptied

    def start_sending(self, send_audio_callback):
        """
        Start the asynchronous sending task

        Args:
            send_audio_callback: callback for sending audio

        Returns:
            asyncio.Task: sending task
        """

        async def _send_loop():
            try:
                while True:
                    # Wait for the queue-has-data event instead of polling, to avoid using CPU
                    await self.queue_has_data_event.wait()

                    await self.check_queue(send_audio_callback)
            except asyncio.CancelledError:
                self.logger.bind(tag=TAG).debug("Audio sending loop stopped")
            except Exception as e:
                self.logger.bind(tag=TAG).error(f"Audio sending loop exception: {e}")

        self.pending_send_task = asyncio.create_task(_send_loop())
        return self.pending_send_task

    def stop_sending(self):
        """Stop the sending task"""
        if self.pending_send_task and not self.pending_send_task.done():
            self.pending_send_task.cancel()
            self.logger.bind(tag=TAG).debug("Audio sending task cancelled")
