# 自定义映射关闭与退格连发恢复

适用：包含mapping-disable-repeat修复的公开macOS构建。遵守[硬件合同](HardwareCompatibilityContract.md)
与[语音合同](HardwareVoiceAudioContract.md)；不修改产品门槛。

## 自动化与证据

使用生产BridgeAppModel路由、独立AppSettings、InteractionClock和只计数的perform，不发送系统事件。
先按住形成连发，再关闭总开关；不推进时钟就必须停止跟踪，继续推进也不能增加动作。
同时覆盖多来源、待定单击、关闭时新按下/迟到松键、重开后的迟到松键及新一轮正常按下。
旧行为下两项回归失败，修复后结果在当前PR分别记录。

```sh
swift test --disable-keychain --filter 'RemoteButtonInteractionTests|G9N9N|RemoteButtonsTests|ChromecastIntegrationTests'
```

## 真实按键

1. 仅在可丢弃的样本文字框测试，确认焦点在Mac。不要在真实文稿中重现持续删除。
2. 静音键配置退格，按住模式repeatSingle。短按一次应删除一个字；按住应连续删除，松开后计数停止。
3. 在受控样本场景关闭自定义按键，不得继续连发、补发待定单击或留下按下高亮。
   只切到另一个前台应用不能独立证明总开关修复，因为前台变化本身也会取消旧交互。
4. 关闭时继续短按/松开，不得执行自定义动作；重新开启后必须用一次新的真实按下恢复。
5. 复核确定Enter、返回Esc、方向、复制/粘贴及原有配置；连续说两句，确认浮窗与文字仍正常。
6. 不为此重置权限、配对、驱动或系统服务。70秒扩展验收保持此前暂缓范围。

## 日志与失败判定

仅收集宿主脱敏日志中的BUTTON HOLD终态、mapping_disabled原因、动作计数及语音generation/排空计数。
不记录样本文字之外的内容、转写、原始HCI流或设备身份。
关闭后有新的动作、迟到松键执行单击、重开后第一轮不工作、普通键或语音回退均判失败。
配置已保存、事件已提交、模拟回放通过和真实删除成功分别记录，不互相替代。
