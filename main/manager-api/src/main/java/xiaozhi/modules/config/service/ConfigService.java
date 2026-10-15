package xiaozhi.modules.config.service;

import java.util.List;
import java.util.Map;

public interface ConfigService {
    /**
     * Get server configuration
     *
     * @param isCache whether to cache
     * @return configuration information
     */
    Map<String, Object> getConfig(Boolean isCache);

    /**
     * Get agent model configuration
     *
     * @param macAddress     MAC address
     * @param selectedModule models already instantiated by the client
     * @return model configuration information
     */
    Map<String, Object> getAgentModels(String macAddress, Map<String, String> selectedModule);

    /**
     * Get agent replacement words
     *
     * @param macAddress device MAC address
     * @return replacement word list, in a format such as ["template1|template01", "template2|template02"]
     */
    List<String> getCorrectWords(String macAddress);
}
