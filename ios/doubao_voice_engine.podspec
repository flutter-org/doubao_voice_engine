Pod::Spec.new do |s|
  s.name             = 'doubao_voice_engine'
  s.version          = '0.0.1'
  s.summary          = '豆包语音端到端实时语音大模型 Flutter 插件'
  s.description      = <<-DESC
基于豆包端到端实时语音大模型，提供低延迟、双向流式语音交互能力。
                       DESC
  s.homepage         = 'https://github.com/example/doubao_voice_engine'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'

  # 豆包语音引擎 SDK
  s.dependency 'SpeechEngineToB', '0.0.14.7'

  # 网络库（0.0.14+ 改为 SocketRocket）
  s.dependency 'SocketRocket', '0.6.1'

  s.platform = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
