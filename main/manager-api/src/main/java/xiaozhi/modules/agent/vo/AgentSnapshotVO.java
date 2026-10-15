package xiaozhi.modules.agent.vo;

import java.util.Date;
import java.util.List;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import xiaozhi.modules.agent.dto.AgentSnapshotDataDTO;

@Data
@Schema(description = "Agent configuration snapshot")
public class AgentSnapshotVO {
    private String id;
    private String agentId;
    @Schema(description = "Owner user ID, indicating the agent owner to whom this snapshot belongs")
    private Long userId;
    private Integer versionNo;
    private List<String> changedFields;
    private List<String> fieldOrder;
    private String source;
    @Schema(description = "Restore source snapshot ID, only has a value for restore result versions")
    private String restoreFromSnapshotId;
    @Schema(description = "Restore source version number, only has a value for restore result versions")
    private Integer restoreFromVersionNo;
    @Schema(description = "Creator, indicating the operator who triggered this snapshot write")
    private Long creator;
    private Date createdAt;
    private AgentSnapshotDataDTO snapshotData;
    private AgentSnapshotDataDTO afterSnapshotData;
    @Schema(description = "Sanitized current configuration corresponding to the restore preview, only has a value in the detail API")
    private AgentSnapshotDataDTO currentSnapshotData;
    @Schema(description = "Current configuration state fingerprint corresponding to the restore preview, only has a value in the detail API")
    private String currentStateToken;
}
