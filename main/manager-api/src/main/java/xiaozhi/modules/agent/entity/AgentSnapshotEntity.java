package xiaozhi.modules.agent.entity;

import java.util.Date;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@TableName("ai_agent_snapshot")
@Schema(description = "Agent configuration snapshot")
public class AgentSnapshotEntity {

    @TableId(type = IdType.ASSIGN_UUID)
    @Schema(description = "Snapshot ID")
    private String id;

    @Schema(description = "Agent ID")
    private String agentId;

    @Schema(description = "Owning user ID")
    private Long userId;

    @Schema(description = "Version number")
    private Integer versionNo;

    @Schema(description = "Snapshot data JSON")
    private String snapshotData;

    @Schema(description = "Changed fields JSON")
    private String changedFields;

    @Schema(description = "Snapshot source")
    private String source;

    @Schema(description = "Restore source snapshot ID")
    private String restoreFromSnapshotId;

    @Schema(description = "Restore source version number")
    private Integer restoreFromVersionNo;

    @Schema(description = "Creator")
    private Long creator;

    @Schema(description = "Creation time")
    private Date createdAt;

    @Schema(description = "Snapshot data masking rule version")
    private Integer redactionVersion;
}
