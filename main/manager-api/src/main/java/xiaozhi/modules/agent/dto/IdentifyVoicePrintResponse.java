package xiaozhi.modules.agent.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.Data;

/**
 * Object returned by the voiceprint identification API
 */
@Data
public class IdentifyVoicePrintResponse {
    /**
     * Best-matching voiceprint id
     */
    @JsonProperty("speaker_id")
    private String speakerId;
    /**
     * Voiceprint score
     */
    private Double score;
}
