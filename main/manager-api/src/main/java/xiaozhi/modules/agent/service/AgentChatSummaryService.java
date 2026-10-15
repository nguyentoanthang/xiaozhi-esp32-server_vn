package xiaozhi.modules.agent.service;

/**
 * Agent chat history summary service interface
 */
public interface AgentChatSummaryService {

    /**
     * Generate a chat summary by session ID and save it to the agent's memory
     * 
     * @param sessionId Session ID
     * @return Save result
     */
    boolean generateAndSaveChatSummary(String sessionId);

    /**
     * Generate a chat title by session ID and save it
     *
     * @param sessionId Session ID
     * @return Whether successful
     */
    boolean generateAndSaveChatTitle(String sessionId);
}