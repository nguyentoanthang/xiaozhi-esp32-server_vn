package xiaozhi.modules.sys.service;

import xiaozhi.common.page.PageData;
import xiaozhi.common.service.BaseService;
import xiaozhi.modules.sys.dto.AdminPageUserDTO;
import xiaozhi.modules.sys.dto.PasswordDTO;
import xiaozhi.modules.sys.dto.SysUserDTO;
import xiaozhi.modules.sys.entity.SysUserEntity;
import xiaozhi.modules.sys.vo.AdminPageUserVO;

/**
 * System user
 */
public interface SysUserService extends BaseService<SysUserEntity> {

    SysUserDTO getByUsername(String username);

    SysUserDTO getByUserId(Long userId);

    void save(SysUserDTO dto);

    /**
     * Delete the specified user, along with the associated devices and agents
     * 
     * @param ids
     */
    void deleteById(Long ids);

    /**
     * Verify whether a password change is allowed
     * 
     * @param userId      user ID
     * @param passwordDTO password verification parameters
     */
    void changePassword(Long userId, PasswordDTO passwordDTO);

    /**
     * Change the password directly, without verification
     * 
     * @param userId   user ID
     * @param password Password
     */
    void changePasswordDirectly(Long userId, String password);

    /**
     * Reset password
     * 
     * @param userId user ID
     * @return a randomly generated password that meets the policy
     */
    String resetPassword(Long userId);

    /**
     * Admin paginated user information
     * 
     * @param dto pagination search parameters
     * @return paginated user list data
     */
    PageData<AdminPageUserVO> page(AdminPageUserDTO dto);

    /**
     * Batch update user status
     * 
     * @param status  User status
     * @param userIds array of user IDs
     */
    void changeStatus(Integer status, String[] userIds);

    /**
     * Get whether user registration is allowed
     * 
     * @return whether user registration is allowed
     */
    boolean getAllowUserRegister();
}
