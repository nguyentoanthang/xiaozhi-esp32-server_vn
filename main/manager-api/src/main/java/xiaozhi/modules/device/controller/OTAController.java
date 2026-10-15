package xiaozhi.modules.device.controller;

import java.nio.charset.StandardCharsets;

import org.apache.commons.lang3.StringUtils;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.ObjectMapper;

import io.swagger.v3.oas.annotations.Hidden;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import xiaozhi.common.constant.Constant;
import xiaozhi.modules.device.dto.DeviceReportReqDTO;
import xiaozhi.modules.device.dto.DeviceReportRespDTO;
import xiaozhi.modules.device.entity.DeviceEntity;
import xiaozhi.modules.device.service.DeviceService;
import xiaozhi.modules.sys.service.SysParamsService;

@Tag(name = "Device Management", description = "OTA related APIs")
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/ota/")
public class OTAController {
    private final DeviceService deviceService;
    private final SysParamsService sysParamsService;

    @Operation(summary = "Check OTA version and device activation status")
    @PostMapping
    public ResponseEntity<String> checkOTAVersion(
            @RequestBody DeviceReportReqDTO deviceReportReqDTO,
            @Parameter(name = "Device-Id", description = "Unique device identifier", required = true, in = ParameterIn.HEADER) @RequestHeader("Device-Id") String deviceId,
            @Parameter(name = "Client-Id", description = "Client identifier", required = false, in = ParameterIn.HEADER) @RequestHeader(value = "Client-Id", required = false) String clientId) {
        if (StringUtils.isBlank(deviceId)) {
            return createResponse(DeviceReportRespDTO.createError("Device ID is required"));
        }
        if (StringUtils.isBlank(clientId)) {
            clientId = deviceId;
        }
        boolean macAddressValid = isMacAddressValid(deviceId);
        // Device Id and Mac address should be identical, and the application field is required
        if (!macAddressValid) {
            return createResponse(DeviceReportRespDTO.createError("Invalid device ID"));
        }
        return createResponse(deviceService.checkDeviceActive(deviceId, clientId, deviceReportReqDTO));
    }

    @Operation(summary = "Quickly check device activation status")
    @PostMapping("activate")
    public ResponseEntity<String> activateDevice(
            @Parameter(name = "Device-Id", description = "Unique device identifier", required = true, in = ParameterIn.HEADER) @RequestHeader("Device-Id") String deviceId,
            @Parameter(name = "Client-Id", description = "Client identifier", required = false, in = ParameterIn.HEADER) @RequestHeader(value = "Client-Id", required = false) String clientId) {
        if (StringUtils.isBlank(deviceId)) {
            return ResponseEntity.status(202).build();
        }
        DeviceEntity device = deviceService.getDeviceByMacAddress(deviceId);
        if (device == null) {
            return ResponseEntity.status(202).build();
        }
        return ResponseEntity.ok("success");
    }

    @GetMapping
    @Hidden
    public ResponseEntity<String> getOTA() {
        String mqttUdpConfig = sysParamsService.getValue(Constant.SERVER_MQTT_GATEWAY, false);
        if (StringUtils.isBlank(mqttUdpConfig)) {
            return ResponseEntity.ok("The OTA API is not working properly: the mqtt_gateway address is missing. Please log in to the control panel and find the [server.mqtt_gateway] configuration in Parameter Management");
        }
        String wsUrl = sysParamsService.getValue(Constant.SERVER_WEBSOCKET, true);
        if (StringUtils.isBlank(wsUrl) || wsUrl.equals("null")) {
            return ResponseEntity.ok("The OTA API is not working properly: the websocket address is missing. Please log in to the control panel and find the [server.websocket] configuration in Parameter Management");
        }
        String otaUrl = sysParamsService.getValue(Constant.SERVER_OTA, true);
        if (StringUtils.isBlank(otaUrl) || otaUrl.equals("null")) {
            return ResponseEntity.ok("The OTA API is not working properly: the ota address is missing. Please log in to the control panel and find the [server.ota] configuration in Parameter Management");
        }
        return ResponseEntity.ok("The OTA API is running normally, number of websocket clusters: " + wsUrl.split(";").length);
    }

    @SneakyThrows
    private ResponseEntity<String> createResponse(DeviceReportRespDTO deviceReportRespDTO) {
        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.setSerializationInclusion(JsonInclude.Include.NON_NULL);
        String json = objectMapper.writeValueAsString(deviceReportRespDTO);
        byte[] jsonBytes = json.getBytes(StandardCharsets.UTF_8);
        return ResponseEntity
                .ok()
                .contentType(MediaType.APPLICATION_JSON)
                .contentLength(jsonBytes.length)
                .body(json);
    }

    /**
     * Simple (non-strict) check of whether the mac address is valid
     * 
     * @param macAddress
     * @return
     */
    private boolean isMacAddressValid(String macAddress) {
        if (StringUtils.isBlank(macAddress)) {
            return false;
        }
        // A MAC address is usually 12 hexadecimal digits, and may contain colon or hyphen separators
        String macPattern = "^([0-9A-Za-z]{2}[:-]){5}([0-9A-Za-z]{2})$";
        return macAddress.matches(macPattern);
    }
}
