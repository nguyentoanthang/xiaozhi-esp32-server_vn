package xiaozhi.modules.agent.dto;

import lombok.Data;

/**
 * Save agent voiceprint dto
 *
 * @author zjy
 */
@Data
public class AgentVoicePrintSaveDTO {
    /**
     * Associated agent id
     */
    private String agentId;
    /**
     * Audio file id
     */
    private String audioId;
    /**
     * Name of the person the voiceprint belongs to
     */
    private String sourceName;
    /**
     * Description of the person the voiceprint belongs to
     */
    private String introduce;
}
