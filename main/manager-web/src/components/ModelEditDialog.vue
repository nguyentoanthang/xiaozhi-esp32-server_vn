<template>
  <CustomDialog
    :title="$t('modelConfigDialog.editModel')"
    :visible.sync="dialogVisible"
    width="960px"
    size="large"
    class="model-edit-dialog"
    :confirmLoading="saving"
    @confirm="handleSave"
    @close="handleClose"
    @open="handleOpen"
  >
    <div class="header-row">
      <div class="section-title">{{ $t("modelConfigDialog.modelInfo") }}</div>
      <div class="switch-group">
        <div class="switch-item">
          <span class="switch-label">{{ $t("modelConfigDialog.enable") }}</span>
          <el-switch v-model="form.isEnabled" :active-value="1" :inactive-value="0" class="custom-switch"></el-switch>
        </div>
        <div class="switch-item hidden">
          <span class="switch-label">{{ $t("modelConfigDialog.setDefault") }}</span>
          <el-switch v-model="form.isDefault" :active-value="1" :inactive-value="0" class="custom-switch"></el-switch>
        </div>
      </div>
    </div>

    <div class="section-divider"></div>

    <el-form :model="form" ref="form" label-width="auto" label-position="left">
      <div class="form-row">
        <el-form-item :label="$t('modelConfigDialog.modelName')" prop="name" style="flex: 1">
          <el-input v-model="form.modelName" :placeholder="$t('modelConfigDialog.enterModelName')"></el-input>
        </el-form-item>
        <el-form-item :label="$t('modelConfigDialog.modelCode')" prop="code" style="flex: 1">
          <el-input v-model="form.modelCode" :placeholder="$t('modelConfigDialog.enterModelCode')"></el-input>
        </el-form-item>
      </div>

      <div class="form-row">
        <el-form-item :label="$t('modelConfigDialog.supplier')" prop="supplier" style="flex: 1">
          <el-select v-model="form.configJson.type" :placeholder="$t('modelConfigDialog.selectSupplier')"
            style="width: 100%" @focus="loadProviders" filterable>
            <el-option v-for="item in providers" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item :label="$t('modelConfigDialog.sortOrder')" prop="sort" style="flex: 1">
          <el-input v-model.number="form.sort" type="number" :placeholder="$t('modelConfigDialog.enterSortOrder')"></el-input>
        </el-form-item>
      </div>

      <el-form-item :label="$t('modelConfigDialog.docLink')" prop="docUrl" style="margin-bottom: 27px">
        <el-input v-model="form.docLink" :placeholder="$t('modelConfigDialog.enterDocLink')"></el-input>
      </el-form-item>

      <el-form-item :label="$t('modelConfigDialog.remark')" prop="remark" class="prop-remark">
        <el-input v-model="form.remark" type="textarea" :rows="3" :autosize="{ minRows: 3, maxRows: 5 }" :placeholder="$t('modelConfigDialog.enterRemark')"></el-input>
      </el-form-item>
    </el-form>

    <teleport v-if="chunkedCallInfoFields.length">
      <div class="section-title">{{ $t("modelConfigDialog.callInfo") }}</div>
      <div class="section-divider"></div>
    </teleport>

    <el-form :model="form.configJson" ref="callInfoForm" label-width="auto" label-position="left">
      <template>
        <div v-for="(row, rowIndex) in chunkedCallInfoFields" :key="rowIndex" class="form-row">
          <el-form-item v-for="field in row" :key="field.prop" :label="field.label" :prop="field.prop"
            style="flex: 1">
            <template v-if="field.type === 'json-textarea'">
              <el-input v-model="fieldJsonMap[field.prop]" type="textarea" :rows="3"
                :placeholder="$t('modelConfigDialog.enterJsonExample')"
                @change="(val) => handleJsonChange(field.prop, val)" @focus="
                  isSensitiveField(field.prop)
                    ? handleJsonInputFocus(field.prop, fieldJsonMap[field.prop])
                    : undefined
                  " @blur="
                  isSensitiveField(field.prop)
                    ? handleJsonInputBlur(field.prop)
                    : undefined
                  "></el-input>
            </template>

            <el-input v-else v-model="form.configJson[field.prop]" :placeholder="field.placeholder" :type="field.type"
              :show-password="field.type === 'password'" @focus="
                isSensitiveField(field.prop)
                  ? handleInputFocus(field.prop, form.configJson[field.prop])
                  : undefined
                " @blur="
                isSensitiveField(field.prop) ? handleInputBlur(field.prop) : undefined
                "></el-input>
          </el-form-item>
        </div>
      </template>
    </el-form>
  </CustomDialog>
</template>

<script>
import CustomDialog from './CustomDialog.vue';
import Api from "@/apis/api";

export default {
  name: "ModelEditDialog",
  components: { CustomDialog },
  props: {
    visible: { type: Boolean, default: false },
    modelData: {
      type: Object,
      default: () => ({}),
      validator: (value) => typeof value === "object" && !Array.isArray(value),
    },
    modelType: { type: String, required: true },
  },
  data() {
    return {
      dialogVisible: this.visible,
      providers: [],
      providersLoaded: false,
      saving: false,
      allProvidersData: null,
      pendingProviderType: null,
      pendingModelData: null,
      dynamicCallInfoFields: [],
      fieldJsonMap: {}, // stores the string form of JSON fields
      sensitive_keys: [
        "api_key",
        "personal_access_token",
        "access_token",
        "token",
        "secret",
        "access_key_secret",
        "secret_key",
      ],
      originalValues: {}, // stores original values, used to restore on blur
      form: {
        id: "",
        modelType: "",
        modelCode: "",
        modelName: "",
        isDefault: false,
        isEnabled: false,
        docLink: "",
        remark: "",
        sort: 0,
        configJson: {},
      },
    };
  },
  computed: {
    title() {
      return this.modelData.duplicateMode
        ? this.$t("modelConfigDialog.duplicateModel")
        : this.$t("modelConfigDialog.editModel");
    },
    chunkedCallInfoFields() {
      const chunkSize = 2;
      const result = [];
      for (let i = 0; i < this.dynamicCallInfoFields.length; i += chunkSize) {
        result.push(this.dynamicCallInfoFields.slice(i, i + chunkSize));
      }
      return result;
    },
  },
  watch: {
    modelType() {
      this.resetProviders();
      this.loadProviders();
    },
    visible(val) {
      this.dialogVisible = val;
    },
    dialogVisible(val) {
      this.$emit("update:visible", val);
    },
    "form.configJson.type"(newVal) {
      if (newVal && this.providersLoaded) {
        this.loadProviderFields(newVal);
      }
    },
  },
  methods: {
    handleOpen() {
      this.loadProviders();
      if (this.modelData.id) {
        this.loadModelData();
      }
    },
    handleClose() {
      this.saving = false;
      // Handle the flicker issue when closing the dialog
      setTimeout(() => {
        this.resetForm();
      }, 200)
    },
    resetForm() {
      this.form = {
        id: "",
        modelType: "",
        modelCode: "",
        modelName: "",
        isDefault: false,
        isEnabled: false,
        docLink: "",
        remark: "",
        sort: 0,
        configJson: {},
      };
      this.fieldJsonMap = {};
    },
    resetProviders() {
      this.providers = [];
      this.providersLoaded = false;
    },
    loadModelData() {
      if (this.modelData.id) {
        Api.model.getModelConfig(this.modelData.id, ({ data }) => {
          if (data.code === 0 && data.data) {
            let model = data.data;

            if (this.modelData.duplicateMode) {
              model.modelName =
                this.modelData.modelName + this.$t("modelConfigDialog.copySuffix");
              model.modelCode =
                this.modelData.modelCode + this.$t("modelConfigDialog.copySuffix");

              // Handle sensitive fields
              if (model.configJson) {
                Object.keys(model.configJson).forEach((key) => {
                  if (this.isSensitiveField(key) && model.configJson[key]) {
                    const sensitiveName = this.getSensitiveFieldName(key);
                    model.configJson[key] = `your_${sensitiveName}`;
                  }
                });
              }
            }
            this.pendingProviderType = model.configJson.type;
            this.pendingModelData = model;

            if (this.providersLoaded) {
              this.loadProviderFields(model.configJson.type);
            } else {
              this.loadProviders();
            }
          }
        });
      }
    },
    handleSave() {
      this.saving = true; // start the save loading state

      // Process all JSON fields
      Object.keys(this.fieldJsonMap).forEach((key) => {
        const parsed = this.validateJson(this.fieldJsonMap[key]);
        if (parsed !== null) {
          this.form.configJson[key] = parsed;
        }
      });

      const formData = {
        id: this.modelData.id,
        modelCode: this.form.modelCode,
        modelName: this.form.modelName,
        isDefault: this.form.isDefault ? 1 : 0,
        isEnabled: this.form.isEnabled ? 1 : 0,
        docLink: this.form.docLink,
        remark: this.form.remark,
        sort: this.form.sort || 0,
        configJson: { ...this.form.configJson },
      };

      this.$emit("save", {
        provideCode: this.form.configJson.type,
        formData,
        done: () => {
          this.saving = false; // callback after saving completes
        },
      });

      // If the parent component does not handle the done callback, automatically close the loading state after 3 seconds
      setTimeout(() => {
        this.saving = false;
      }, 3000);
    },
    loadProviders() {
      if (this.providersLoaded) return;

      Api.model.getModelProviders(this.modelType, (data) => {
        this.providers = data.map((item) => ({
          label: item.name,
          value: String(item.providerCode),
        }));
        this.providersLoaded = true;
        this.allProvidersData = data;

        if (this.pendingProviderType) {
          this.loadProviderFields(this.pendingProviderType);
        }
      });
    },
    loadProviderFields(providerCode) {
      if (this.allProvidersData) {
        const provider = this.allProvidersData.find(
          (p) => p.providerCode === providerCode
        );
        if (provider) {
          this.dynamicCallInfoFields = JSON.parse(provider.fields || "[]").map((f) => ({
            label: f.label,
            prop: f.key,
            type:
              f.type === "dict"
                ? "json-textarea"
                : f.type === "password"
                  ? "password"
                  : "text",
            placeholder: `Please enter ${f.key}`,
          }));

          if (this.pendingModelData && this.pendingProviderType === providerCode) {
            this.processModelData(this.pendingModelData);
            this.pendingModelData = null;
            this.pendingProviderType = null;
          }
        }
      }
    },
    processModelData(model) {
      let configJson = model.configJson || {};
      this.dynamicCallInfoFields.forEach((field) => {
        if (!configJson.hasOwnProperty(field.prop)) {
          configJson[field.prop] = "";
        } else if (field.type === "json-textarea") {
          this.$set(
            this.fieldJsonMap,
            field.prop,
            this.formatJson(configJson[field.prop])
          );
          configJson[field.prop] = this.ensureObject(configJson[field.prop]);
        } else if (typeof configJson[field.prop] !== "string") {
          configJson[field.prop] = String(configJson[field.prop]);
        }
      });

      this.form = {
        id: model.id,
        modelType: model.modelType,
        modelCode: model.modelCode,
        modelName: model.modelName,
        isDefault: model.isDefault,
        isEnabled: model.isEnabled,
        docLink: model.docLink,
        remark: model.remark,
        sort: Number(model.sort) || 0,
        configJson: { ...configJson },
      };
    },
    handleJsonChange(field, value) {
      const parsed = this.validateJson(value);
      if (parsed !== null) {
        this.form.configJson[field] = parsed;
      }
    },
    validateJson(value) {
      try {
        const parsed = JSON.parse(value);
        if (typeof parsed === "object" && parsed !== null && !Array.isArray(parsed)) {
          return parsed;
        }
        this.$message.error({
          message: 'A dictionary format is required (e.g. {"key":"value"}); saving will use the original data',
          showClose: true,
        });
        return null;
      } catch (e) {
        this.$message.error({
          message: 'Invalid JSON format (e.g. {"key":"value"}); saving will use the original data',
          showClose: true,
        });
        return null;
      }
    },
    formatJson(obj) {
      try {
        return JSON.stringify(obj, null, 2);
      } catch {
        return "";
      }
    },
    ensureObject(value) {
      return typeof value === "object" ? value : {};
    },

    // Detect whether a field is a sensitive field
    isSensitiveField(fieldName) {
      // Convert the field name to lowercase for comparison
      const lowerFieldName = fieldName.toLowerCase();
      // Exactly match the 7 sensitive keywords defined in keyMap
      return this.sensitive_keys.includes(lowerFieldName);
    },

    // Get the display name corresponding to a sensitive field
    getSensitiveFieldName(fieldName) {
      const keyMap = {
        api_key: "API key",
        personal_access_token: "personal access token",
        access_token: "access token",
        token: "token",
        secret: "secret",
        access_key_secret: "access key secret",
        secret_key: "secret key",
      };

      for (const [key, value] of Object.entries(keyMap)) {
        if (fieldName.toLowerCase().includes(key)) {
          return value;
        }
      }
      return "sensitive information";
    },

    // Handle the input focus event
    handleInputFocus(field, value) {
      // If the value contains asterisks, clear the display
      if (value && value.includes("*")) {
        // Store the original value, used to restore on blur
        this.$set(this.originalValues, field, this.form.configJson[field]);
        this.$set(this.form.configJson, field, "");
      }
    },

    // Handle the input blur event
    handleInputBlur(field) {
      // Check whether it is a sensitive field
      if (this.isSensitiveField(field)) {
        // If the value is empty, restore the masked value
        if (!this.form.configJson[field] || this.form.configJson[field].trim() === "") {
          // If there is an original value, restore it; otherwise set the mask hint
          if (this.originalValues[field]) {
            this.$set(this.form.configJson, field, this.originalValues[field]);
          } else {
            const sensitiveName = this.getSensitiveFieldName(field);
            this.$set(this.form.configJson, field, `your_${sensitiveName}`);
          }
          // Clear the temporarily stored original value
          this.$delete(this.originalValues, field);
        }
      }
    },

    // Handle the focus event of JSON fields
    handleJsonInputFocus(field, value) {
      if (value && value.includes("*")) {
        this.$set(this.fieldJsonMap, field, "");
      }
    },

    // Handle the blur event of JSON fields
    handleJsonInputBlur(field) {
      // JSON fields get no special handling because they usually contain no simple sensitive information
    },
  },
};
</script>

<style lang="scss" scoped>
@import '@/styles/global.scss';

.model-edit-dialog {
  ::v-deep .el-dialog__body {
    padding: 24px 40px;
  }

  .header-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 4px;
  }

  .section-title {
    margin-bottom: 10px;
    font-size: 20px;
    font-weight: bold;
    color: #3d4566;
    text-align: left;
  }

  .switch-group {
    display: flex;
    align-items: center;
    gap: 20px;
  }

  .switch-item {
    display: flex;
    align-items: center;

    &.hidden {
      display: none;
    }

    .switch-label {
      margin-right: 8px;
    }
  }

  .section-divider {
    height: 1px;
    background: #e9e9e9;
    margin-bottom: 18px;
  }

  .form-row {
    display: flex;
    gap: 20px;
    margin-bottom: 0;
  }

  ::v-deep .el-input__inner {
    height: 38px;
  }
  ::v-deep .el-form-item {
    margin-bottom: 14px;
  }
  ::v-deep .el-form-item__label {
    line-height: 38px;
  }
}
</style>
