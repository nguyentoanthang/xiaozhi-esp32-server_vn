package xiaozhi.modules.agent.vo;

import lombok.Data;

import java.util.Date;

/**
 * VO for displaying the agent voiceprint list
 */
@Data
public class AgentVoicePrintVO {

    /**
     * Primary key id
     */
    private String id;
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
    /**
     * Creation time
     */
    private Date createDate;
}
