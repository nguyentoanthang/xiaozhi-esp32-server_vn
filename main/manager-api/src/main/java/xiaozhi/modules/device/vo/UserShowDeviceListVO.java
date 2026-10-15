package xiaozhi.modules.device.vo;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonFormat;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "VO for the user's device list display")
public class UserShowDeviceListVO {

    @Schema(description = "app version")
    private String appVersion;

    @Schema(description = "Bound user name")
    private String bindUserName;

    @Schema(description = "Device model")
    private String deviceType;

    @Schema(description = "Device model (board)")
    private String board;

    @Schema(description = "Unique device identifier")
    private String id;

    @Schema(description = "mac address")
    private String macAddress;

    @Schema(description = "Device alias")
    private String alias;

    @Schema(description = "Auto-update switch (0 off / 1 on)")
    private Integer autoUpdate;

    @Schema(description = "Last conversation time")
    private String recentChatTime;

    @Schema(description = "Last connection timestamp (milliseconds)", type = "string", example = "1783689702000")
    private Long lastConnectedAtTimestamp;

    @Schema(description = "Bind timestamp (milliseconds)", type = "string", example = "1783689702000")
    private Long createDateTimestamp;

    @Schema(description = "Bind time (compatibility field, use createDateTimestamp)", deprecated = true)
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "UTC")
    private Date createDate;

}
