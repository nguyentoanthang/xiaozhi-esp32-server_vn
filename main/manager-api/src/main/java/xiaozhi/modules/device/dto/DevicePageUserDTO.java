package xiaozhi.modules.device.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import lombok.Data;

/**
 * DTO for querying all devices
 * 
 * @author zjy
 * @since 2025-3-21
 */
@Data
@Schema(description = "DTO for querying all devices")
public class DevicePageUserDTO {

    @Schema(description = "Device keyword")
    private String keywords;

    @Schema(description = "Page number")
    @Min(value = 0, message = "{page.number}")
    private String page;

    @Schema(description = "Number of columns to display")
    @Min(value = 0, message = "{limit.number}")
    private String limit;
}
