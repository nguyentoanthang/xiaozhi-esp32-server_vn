package xiaozhi.modules.agent.service.biz;

import xiaozhi.modules.agent.dto.AgentChatHistoryReportDTO;

/**
 * Business logic layer for agent chat history
 *
 * @author Goody
 * @version 1.0, 2025/4/30
 * @since 1.0.0
 */
public interface AgentChatHistoryBizService {

    /**
     * Chat report method
     *
     * @param agentChatHistoryReportDTO input object containing the information required for the chat report
     *                                  e.g. device MAC address, file type, content, etc.
     * @return upload result, true for success, false for failure
     */
    Boolean report(AgentChatHistoryReportDTO agentChatHistoryReportDTO);
}
