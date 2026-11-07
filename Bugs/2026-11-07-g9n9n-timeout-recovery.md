# G9N9N 超时取消后不再接受下一次录音

## 现场证据

旧构建在同一进程完成多次正常本机录音后，一段会话因 `audio_timeout` 异常取消。
随后连续多次收到 START/STOP，却没有新的语音 generation、Fn 按下或 PCM。
应用、蓝牙连接与能力协商均仍在，不是进程退出；本次也没有新包安装或测试误停。
重新打开同一构建后，用户确认本机浮窗与文字恢复。

## 根因与修复

原状态机在取消时保留 `cancelled=true`，只接受 MIC_OPEN 或重连解除该状态。
本遥控器下一次按下可以直接发送 START，没有 MIC_OPEN，因此持续被当成旧会话迟到包关闭。
永久回归重放“START→音频→超时取消→迟到START/音频→STOP→下一次直接START”，原实现失败。

修复以有序 STOP 确认被取消会话已经结束，恢复等待下一次真实按下；不靠音频自行重启会话。
STOP 前的迟到 START/音频继续拒绝，STOP 后但下一次 START 前的音频继续忽略。
兼容固件复用或递增 session ID，重复 STOP 不会增加开始或结束次数。
正常尾音缓冲与宿主自然排空保持原流程。

同时修正公开诊断：即使已收到的音频全部播放，forced 结束仍报告失败，保留白名单超时原因；
不能再用 `passed reason=session_stopped` 覆盖本次断流事实。

## 验证与固化边界

原实现的失败回归已复现；修复后定向52项通过，完整1302项/94套件通过。
覆盖取消前后的迟到包、相同/不同session ID、正常尾音、连续会话、重复STOP和forced诊断。
已保留登录启动、G9独立唤醒恢复、稳定本地签名及迁移fixture进程隔离；不增加无限重启守护。
本机版本不包含跨电脑语音路由。本地public G9包通过源码更新，阻止上游通用安装包覆盖该适配。
自动化回放不代表真实无线断流与睡眠已验收，安装后仍须核验真实短句及恢复结果。

## 长录音边界（暂缓）

build29后续长测收到1942帧、959348个16kHz样本，约59.96秒真实音频；
65389ms时因5秒无音频触发cancelled.audio_timeout，completion=forced。
宿主已播完收到的全部样本，pending与interrupted均为0，但不构成长录音通过。
随后收到STOP并记录cancelled_stream_stopped，证明上述取消等待恢复路径在本次现场实际执行。

录音约26.5秒时曾记录sustained，但代码在调用可选onWrite后即打印该字段，
不能证明CoreBluetooth已提交、ATT写入完成或固件接受。无写入处理器的最小回放仍会打印sustained。
另已复现：新START_SEARCH后、正式AUDIO_START前，extend可能仍使用上一轮stream ID；
默认模式Timer在菜单跟踪模式不触发。两项属于已确认代码风险，不能独立归因为本次60秒断流。
现保活为连接级50秒Timer，未在每次AUDIO_START重置；本轮只读调查未改实现。

公开参考[ATVVoice](https://github.com/b0o/ATVVoice#readme)使用10秒保活；
[remote-vibe](https://github.com/jmeviler/remote-vibe/blob/82c4b7accc31af58b06f63cf8b5fb5a862702cbe/Sources/Audio/RemoteAudioSession.swift)
使用4秒保活但在55秒主动结束，不能据此证明本型号能突破60秒。
当前MIC_EXTEND格式与公开v1.0实现一致，实际固件是否续期仍未知；未猜测CAPS租期字段或改写类型。

用户明确选择暂缓70秒验收及相关修复，日常按每段50秒内使用；本轮未增加软件限时、未重装应用。
再次开展该项时应分别验证会话计时/旧回调隔离、真实写入诊断与固件长测，不能降低硬件合同门槛。
