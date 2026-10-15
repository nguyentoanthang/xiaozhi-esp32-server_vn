package xiaozhi.modules.agent.service;


import java.util.List;

/**
 * Agent Mcp access point handling service
 *
 * @author zjy
 */
public interface AgentMcpAccessPointService {
    /**
     * Get the agent's mcp access point address
     * @param id Agent id
     * @return mcp Access point address
     */
   String getAgentMcpAccessAddress(String id);

    /**
     * Get the agent's existing mcp access point tool list
     * @param id Agent id
     * @return Tool list
     */
   List<String> getAgentMcpToolsList(String id);
}
