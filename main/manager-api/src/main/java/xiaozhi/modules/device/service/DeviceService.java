package xiaozhi.modules.device.service;

import java.util.Date;
import java.util.List;
import java.util.Map;

import xiaozhi.common.page.PageData;
import xiaozhi.common.service.BaseService;
import xiaozhi.modules.device.dto.DeviceManualAddDTO;
import xiaozhi.modules.device.dto.DevicePageUserDTO;
import xiaozhi.modules.device.dto.DeviceReportReqDTO;
import xiaozhi.modules.device.dto.DeviceReportRespDTO;
import xiaozhi.modules.device.entity.DeviceEntity;
import xiaozhi.modules.device.vo.UserShowDeviceListVO;

public interface DeviceService extends BaseService<DeviceEntity> {
    /**
     * Get device online data
     */
    String getDeviceOnlineData(String agentId);

    /**
     * Check whether the device is activated
     */
    DeviceReportRespDTO checkDeviceActive(String macAddress, String clientId,
            DeviceReportReqDTO deviceReport);

    /**
     * Get the device list of the specified agent for the user,
     */
    List<DeviceEntity> getUserDevices(Long userId, String agentId);

    /**
     * Get the device list of the specified agent for the user (with time zone handling),
     */
    List<UserShowDeviceListVO> getUserDeviceList(Long userId, String agentId);

    /**
     * Unbind a device
     */
    void unbindDevice(Long userId, String deviceId);

    /**
     * Activate a device
     */
    Boolean deviceActivation(String agentId, String activationCode);

    /**
     * Delete all devices of this user
     * 
     * @param userId user id
     */
    void deleteByUserId(Long userId);

    /**
     * Delete all devices associated with the specified agent
     * 
     * @param agentId agent id
     */
    void deleteByAgentId(String agentId);

    /**
     * Get the number of devices of the specified user
     * 
     * @param userId user id
     * @return device count
     */
    Long selectCountByUserId(Long userId);

    /**
     * Get all device information with paging
     *
     * @param dto paging query parameters
     * @return paged user list data
     */
    PageData<UserShowDeviceListVO> page(DevicePageUserDTO dto);

    /**
     * Get device information by MAC address
     * 
     * @param macAddress MAC address
     * @return device information
     */
    DeviceEntity getDeviceByMacAddress(String macAddress);

    /**
     * Get the activation code by device ID
     * 
     * @param deviceId device ID
     * @return activation code
     */
    String geCodeByDeviceId(String deviceId);

    /**
     * Get the most recent last-connection time among the devices of this agent
     * 
     * @param agentId agent id
     * @return the most recent last-connection time of the device
     */
    Date getLatestLastConnectionTime(String agentId);

    /**
     * Manually add a device
     */
    void manualAddDevice(Long userId, DeviceManualAddDTO dto);

    /**
     * Update device connection information
     */
    void updateDeviceConnectionInfo(String agentId, String deviceId, String appVersion);

    /**
     * Generate the WebSocket authentication token
     *
     * @param clientId client ID
     * @param username username (usually deviceId)
     * @return authentication token string
     * @throws Exception exception when generating the token
     */
    String generateWebSocketToken(String clientId, String username) throws Exception;

    /**
     * Search devices by MAC address
     *
     * @param macAddress MAC address keyword
     * @param userId     user ID
     * @return device list
     */
    List<DeviceEntity> searchDevicesByMacAddress(String macAddress, Long userId);

    /**
     * Get the device tool list
     */
    Object getDeviceTools(String deviceId);

    /**
     * Call a device tool
     */
    Object callDeviceTool(String deviceId, String toolName, Map<String, Object> arguments);

    }