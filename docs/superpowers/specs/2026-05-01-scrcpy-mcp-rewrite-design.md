# scrcpy_mcp 重写设计文档

## 概述

使用 `dart_mcp` 包重写 `scrcpy_mcp`，将其从简单的门面类转变为完整的 MCP Server 实现，支持 Tools、Resources 和 Prompts 三种能力。

## 目标

1. 使用官方 `dart_mcp` SDK 实现标准 MCP 协议
2. 支持作为独立命令行工具运行（Stdio 传输）
3. 支持作为库嵌入到其他应用中
4. 暴露完整的 scrcpy 操作能力

## 架构设计

### 包结构

```
scrcpy_mcp/
  lib/
    scrcpy_mcp.dart              # 导出库接口
    src/
      scrcpy_mcp_server.dart     # MCPServer 实现（核心）
      scrcpy_mcp_adapters.dart   # ADB/Logger 适配器（保留）
  bin/
    scrcpy_mcp.dart              # 命令行入口
  pubspec.yaml                   # 添加 dart_mcp 依赖
```

### 核心类

```dart
class ScrcpyMcpServer extends MCPServer
    with ToolsSupport, ResourcesSupport, PromptsSupport {

  final ScrcpyAdb _adb;
  ScrcpyServer? _activeServer;

  ScrcpyMcpServer.fromStreamChannel(super.channel, {required ScrcpyAdb adb});

  @override
  FutureOr<InitializeResult> initialize(InitializeRequest request) {
    _registerTools();
    _registerResources();
    _registerPrompts();
    return super.initialize(request);
  }
}
```

## MCP 能力定义

### Tools（工具）

| 工具名 | 描述 | 输入参数 | 返回结果 |
|--------|------|----------|----------|
| `list_devices` | 列出已连接设备 | 无 | 设备 ID 列表 |
| `start_mirroring` | 启动屏幕镜像 | `device_id: string` | 镜像状态、端口 |
| `stop_mirroring` | 停止镜像会话 | 无 | 停止确认 |
| `inject_key` | 发送按键事件 | `keycode: int`, `action?: int` | 发送确认 |
| `inject_touch` | 发送触摸事件 | `x, y, width, height, action?` | 发送确认 |
| `inject_text` | 输入文本 | `text: string` | 发送确认 |
| `inject_scroll` | 发送滚动事件 | `x, y, width, height, hScroll, vScroll` | 发送确认 |

### Resources（资源）

| 资源 URI | 描述 | 内容格式 |
|----------|------|----------|
| `device://list` | 当前连接的设备列表 | JSON 数组 |
| `mirroring://status` | 当前镜像状态 | JSON 对象 |

### Prompts（提示模板）

| 提示名 | 描述 | 参数 |
|--------|------|------|
| `control_device` | 设备控制助手 | `device_id?: string` |
| `troubleshoot` | 设备问题排查 | `issue?: string` |

## 依赖变更

```yaml
dependencies:
  dart_mcp: ^0.5.1  # 新增
  autoglm_adb:
    path: ../packages/autoglm_adb
  autoglm_logger:
    path: ../packages/autoglm_logger
  scrcpy_view:
    path: ../scrcpy_view
```

## 命令行入口

```dart
// bin/scrcpy_mcp.dart
void main() async {
  final adb = AdbClient(adbPath: 'adb');
  final server = ScrcpyMcpServer.fromStreamChannel(
    StreamChannel(stdin, stdout),
    adb: ScrcpyMcpAdb(adb),
  );
  await server.done;
}
```

## 实现步骤

1. 更新 `pubspec.yaml`，添加 `dart_mcp` 依赖
2. 重写 `scrcpy_mcp_server.dart`，继承 `MCPServer` 并混入能力
3. 实现 Tools 注册和处理逻辑
4. 实现 Resources 注册和处理逻辑
5. 实现 Prompts 注册和处理逻辑
6. 创建命令行入口 `bin/scrcpy_mcp.dart`
7. 更新 `scrcpy_mcp.dart` 导出接口
8. 运行测试验证

## 测试策略

- 单元测试：测试各个工具、资源、提示的实现
- 集成测试：测试 MCP 协议交互
- 手动测试：使用 MCP 客户端连接验证
