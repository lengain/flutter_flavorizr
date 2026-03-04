# flutter_flavorizr `ohos:target` 支持需求文档

## 1. 需求背景

当前 `flutter_flavorizr` 已支持将 `ohos.product` 映射到工程级 `build-profile.json5` 的 `app.products[]`，但尚未支持对 **entry 模块 target 构建信息** 的声明式配置。  
HarmonyOS 多 target 场景下，需要在 `flavorizr.yaml` 中配置 `ohos.target`，并自动写入 `example/ohos/entry/build-profile.json5` 的 `targets[]`。

## 2. 需求目标

- 新增 `ohos.target` 配置解析能力。
- 将每个 flavor 的 `ohos.target` 映射到 `ohos/entry/build-profile.json5` 的 `targets[]`。
- `targets[].name` 与当前 flavor 对应的 OHOS 名称保持一致（即 `ohos.name`）。
- 支持多 flavor、可重复执行（幂等），不重复追加。
- 如果没有配置`ohos.target`，则提供默认值。默认值写入 `example/ohos/entry/build-profile.json5` 的 `targets[]`中，有如下配置`targets[].name`,`targets[].source.pages`,`targets[].source.sourceRoots`,`targets[].resource.directories`


## 3. 配置契约（YAML）

### 3.1 输入配置

```yaml
flavors:
  apple:
    ohos:
      applicationId: "com.example.apple.ohos"
      name: "apple_debug"
      target:
        source:
          pages:
            - "pages/Index"
          sourceRoots:
            - "./src/apple_debug"
        resource:
          directories:
            - "./src/main/apple_debug/resources"
            - "./src/main/resources"
```

> 说明：`ohos.target` 为可选字段；未配置时不生成对应 `targets[]` 条目。

### 3.2 字段定义

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `ohos.target.source.pages` | `List<String>` | 否 | 入口页面列表 |
| `ohos.target.source.sourceRoots` | `List<String>` | 否 | 源码根目录列表 |
| `ohos.target.resource.directories` | `List<String>` | 否 | 资源目录列表 |

校验规则：
- 若提供，以上字段必须为字符串数组。
- 空数组允许写入；字段缺失则不写该字段。
- `ohos.target` 不是对象时应报配置错误。

## 4. 输出映射规则

目标文件：`ohos/entry/build-profile.json5`  
目标节点：`targets[]`

每个 flavor 的映射结果如下：

```json
{
  "name": "apple_debug",
  "source": {
    "pages": [
      "pages/Index"
    ],
    "sourceRoots": [
      "./src/apple_debug"
    ]
  },
  "resource": {
    "directories": [
      "./src/main/apple_debug/resources",
      "./src/main/resources"
    ]
  }
}
```

映射规则：
1. `targets[].name = ohos.name`（若缺失则按现有产品名回退策略）。
2. `source.pages`、`source.sourceRoots`、`resource.directories` 按键名一一映射。
3. 未配置的子字段不输出。
4. `resource.directories` 中如果没有包含"./src/main/resources"，映射时，自动加上"./src/main/resources"


## 5. 合并与幂等策略

- 按 `targets[].name` 合并：
  - 同名：覆盖 flavorizr 管理字段（`source`、`resource`）。
  - 异名：保留原有条目。
- 重复执行 `flutter pub run flutter_flavorizr` 后文件内容应保持稳定（无重复条目、无顺序抖动）。
- 当 flavor 被删除时，对应 target 的删除策略保持与现有 `ohos:products` 一致（建议同样采用“以当前配置为准”的覆盖策略）。

## 6.构建配置文件
`entry/build-profile.json5`文件映射完成后，需要进行资源构建
- 按照`targets[].source.sourceRoots`列表中的文件路径，先判断是否为空，为空则新建文件夹，并把`./src/main/resources`文件夹移动到`targets[].source.sourceRoots`列表中的文件路径下，改文件夹和`targets[].resource.directories`中的`./src/main/ohos:name/resources`对应上
- 如果未设置`targets[].resource.directories`,则自动构建，包含两个文件夹，一个是`./src/main/resources`,另一个就是`./src/main/ohos:name/resources`,
- 当向`./src/main/ohos:name/resources`同步`./src/main/resources`内容时，若目标文件已存在则跳过，不允许覆盖已有文件

## 7. 与现有能力的关系

- 本需求仅新增 `ohos.target -> entry/build-profile.json5:targets[]` 链路。
- 不改变现有 `ohos.product -> ohos/build-profile.json5:app.products[]` 链路。
- 不引入 `flavorizr` 节点写入到 OHOS 官方工程配置文件。

## 8. 验收标准

满足以下条件视为验收通过：

1. `flavorizr.yaml` 中配置 `ohos.target` 后，可在 `ohos/entry/build-profile.json5` 生成同名 `targets[]` 条目。
2. 生成结果字段结构与本文件第 4 节示例一致。
3. 多 flavor 场景下可生成多个 target，且按 name 正确对应。
4. 重复执行两次以上结果一致（幂等）。
5. 未配置 `ohos.target` 的 flavor 不生成 target 条目。
6. 配置类型错误时有明确报错信息。

## 9. 测试建议

- 单测：
  - 解析 `ohos.target` 成功/失败路径。
  - target 合并策略（同名覆盖、异名保留）。
  - 幂等验证。
- 集成测试：
  - 在 `example` 下执行 `flutter pub run flutter_flavorizr`，核对 `ohos/entry/build-profile.json5` 中 `targets[]`。

