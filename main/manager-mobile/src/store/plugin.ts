import type { AgentFunction, PluginDefinition } from '@/api/agent/types'
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const usePluginStore = defineStore(
  'plugin',
  () => {
    // All available plugins
    const allFunctions = ref<PluginDefinition[]>([])

    // Plugin configuration of the current agent
    const currentFunctions = ref<AgentFunction[]>([])

    // ID of the agent currently being edited
    const currentAgentId = ref('')

    // Set all available plugins
    const setAllFunctions = (functions: PluginDefinition[]) => {
      allFunctions.value = functions
    }

    // Set the plugin configuration of the current agent
    const setCurrentFunctions = (functions: AgentFunction[]) => {
      currentFunctions.value = functions
    }

    // Set the current agent ID
    const setCurrentAgentId = (agentId: string) => {
      currentAgentId.value = agentId
    }

    // Update the plugin configuration (called when saving)
    const updateFunctions = (functions: AgentFunction[]) => {
      currentFunctions.value = functions
    }

    // Clear data
    const clear = () => {
      allFunctions.value = []
      currentFunctions.value = []
      currentAgentId.value = ''
    }

    return {
      allFunctions,
      currentFunctions,
      currentAgentId,
      setAllFunctions,
      setCurrentFunctions,
      setCurrentAgentId,
      updateFunctions,
      clear,
    }
  },
  {
    persist: false, // Not persisted, reloaded every time the page is entered
  },
)
