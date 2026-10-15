package xiaozhi.modules.sys.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.io.Serializable;
import java.util.Date;

/**
 * Dictionary data VO
 */
@Data
@Schema(description = "Dictionary data VO")
public class SysDictDataVO implements Serializable {
    @Schema(description = "Primary key")
    private Long id;

    @Schema(description = "Dictionary type ID")
    private Long dictTypeId;

    @Schema(description = "Dictionary label")
    private String dictLabel;

    @Schema(description = "Dictionary value")
    private String dictValue;

    @Schema(description = "Remarks")
    private String remark;

    @Schema(description = "Sort order")
    private Integer sort;

    @Schema(description = "Created by")
    private Long creator;

    @Schema(description = "Creator name")
    private String creatorName;

    @Schema(description = "Create time")
    private Date createDate;

    @Schema(description = "Updated by")
    private Long updater;

    @Schema(description = "Updater name")
    private String updaterName;

    @Schema(description = "Update time")
    private Date updateDate;
}
