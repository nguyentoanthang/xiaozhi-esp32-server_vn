DROP TABLE IF EXISTS sys_user;
DROP TABLE IF EXISTS sys_params;
DROP TABLE IF EXISTS sys_user_token;
DROP TABLE IF EXISTS sys_dict_type;
DROP TABLE IF EXISTS sys_dict_data;

-- System user
CREATE TABLE sys_user (
  id bigint NOT NULL COMMENT 'id',
  username varchar(50) NOT NULL COMMENT 'Username',
  password varchar(100) COMMENT 'Password',
  super_admin tinyint unsigned COMMENT 'Super admin   0: No   1: Yes',
  status tinyint COMMENT 'Status  0: Disabled   1: Normal',
  create_date datetime COMMENT 'Created at',
  updater bigint COMMENT 'Updated by',
  creator bigint COMMENT 'Created by',
  update_date datetime COMMENT 'Updated at',
  primary key (id),
  unique key uk_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='System user';

-- System user Token
CREATE TABLE sys_user_token (
  id bigint NOT NULL COMMENT 'id',
  user_id bigint NOT NULL COMMENT 'User id',
  token varchar(100) NOT NULL COMMENT 'User token',
  expire_date datetime COMMENT 'Expires at',
  update_date datetime COMMENT 'Updated at',
  create_date datetime COMMENT 'Created at',
  PRIMARY KEY (id),
  UNIQUE KEY user_id (user_id),
  UNIQUE KEY token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='System user Token';

-- Parameter management
create table sys_params
(
  id                   bigint NOT NULL COMMENT 'id',
  param_code           varchar(32) COMMENT 'Parameter code',
  param_value          varchar(2000) COMMENT 'Parameter value',
  param_type           tinyint unsigned default 1 COMMENT 'Type   0: System parameter   1: Non-system parameter',
  remark               varchar(200) COMMENT 'Remarks',
  creator              bigint COMMENT 'Created by',
  create_date          datetime COMMENT 'Created at',
  updater              bigint COMMENT 'Updated by',
  update_date          datetime COMMENT 'Updated at',
  primary key (id),
  unique key uk_param_code (param_code)
)ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4 COMMENT='Parameter management';

-- Dictionary type
create table sys_dict_type
(
    id                   bigint NOT NULL COMMENT 'id',
    dict_type            varchar(100) NOT NULL COMMENT 'Dictionary type',
    dict_name            varchar(255) NOT NULL COMMENT 'Dictionary name',
    remark               varchar(255) COMMENT 'Remarks',
    sort                 int unsigned COMMENT 'Sort',
    creator              bigint COMMENT 'Created by',
    create_date          datetime COMMENT 'Created at',
    updater              bigint COMMENT 'Updated by',
    update_date          datetime COMMENT 'Updated at',
    primary key (id),
    UNIQUE KEY(dict_type)
)ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4 COMMENT='Dictionary type';

-- Dictionary data
create table sys_dict_data
(
    id                   bigint NOT NULL COMMENT 'id',
    dict_type_id         bigint NOT NULL COMMENT 'Dictionary type ID',
    dict_label           varchar(255) NOT NULL COMMENT 'Dictionary label',
    dict_value           varchar(255) COMMENT 'Dictionary value',
    remark               varchar(255) COMMENT 'Remarks',
    sort                 int unsigned COMMENT 'Sort',
    creator              bigint COMMENT 'Created by',
    create_date          datetime COMMENT 'Created at',
    updater              bigint COMMENT 'Updated by',
    update_date          datetime COMMENT 'Updated at',
    primary key (id),
    unique key uk_dict_type_value (dict_type_id, dict_value),
    key idx_sort (sort)
)ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4 COMMENT='Dictionary data';