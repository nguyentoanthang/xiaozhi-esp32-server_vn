package xiaozhi.modules.agent.service;

import java.util.List;

import xiaozhi.modules.agent.dto.AgentVoicePrintSaveDTO;
import xiaozhi.modules.agent.dto.AgentVoicePrintUpdateDTO;
import xiaozhi.modules.agent.vo.AgentVoicePrintVO;

/**
 * Agent voiceprint handling service
 *
 * @author zjy
 */
public interface AgentVoicePrintService {
    /**
     * Add a new voiceprint for the agent
     *
     * @param dto Data for saving the agent voiceprint
     * @return T: success F: failure
     */
    boolean insert(AgentVoicePrintSaveDTO dto);

    /**
     * Delete the specified voiceprint of the agent
     *
     * @param userId       The currently logged-in user id
     * @param voicePrintId Voiceprint id
     * @return Whether successful T: success F: failure
     */
    boolean delete(Long userId, String voicePrintId);

    /**
     * Get all voiceprint data of the specified agent
     *
     * @param userId  The currently logged-in user id
     * @param agentId Agent id
     * @return Voiceprint data collection
     */
    List<AgentVoicePrintVO> list(Long userId, String agentId);

    /**
     * Update the specified voiceprint data of the agent
     *
     * @param userId The currently logged-in user id
     * @param dto    Updated voiceprint data
     * @return Whether successful T: success F: failure
     */
    boolean update(Long userId, AgentVoicePrintUpdateDTO dto);

}
