package xiaozhi.modules.device.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Schema(description = "Update device address book permission")
public class DeviceAddressBookPermissionDTO {

    @NotBlank(message = "MAC address cannot be empty")
    @Schema(description = "This device's MAC address")
    private String macAddress;

    @NotBlank(message = "Target MAC address cannot be empty")
    @Schema(description = "Peer device's MAC address")
    private String targetMac;

    @Schema(description = "Whether calling is permitted")
    private Boolean hasPermission;
}