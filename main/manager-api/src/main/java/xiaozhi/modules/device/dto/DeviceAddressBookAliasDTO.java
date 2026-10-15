package xiaozhi.modules.device.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Schema(description = "Update device address book alias")
public class DeviceAddressBookAliasDTO {

    @NotBlank(message = "MAC address cannot be empty")
    @Schema(description = "This device's MAC address")
    private String macAddress;

    @NotBlank(message = "Target MAC address cannot be empty")
    @Schema(description = "Peer device's MAC address")
    private String targetMac;

    @Schema(description = "How I address the peer")
    private String alias;
}