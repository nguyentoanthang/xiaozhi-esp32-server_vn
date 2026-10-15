package xiaozhi.modules.sys.service;


import java.util.function.Consumer;

/**
 * Defines a system user utility class to avoid a circular dependency with the user module
 * For example, users and devices depend on each other: users need to fetch all devices, and devices need to fetch each device's username
 * @author zjy
 * @since 2025-4-2
 */
public interface SysUserUtilService {
    /**
     * Assign the username
     * @param userId user ID
     * @param setter setter method
     */
    void assignUsername( Long userId, Consumer<String> setter);
}
