Pod::Spec.new do |s|

s.name     = 'OOModel'
s.version  = '1.0.0'
s.license  = 'MIT'
s.summary  = 'A fast && useful json model framework'
s.homepage = 'https://github.com/oyh5233/OOModel'
s.author   = { 'oyh5233' => 'oyh5233@outlook.com' }
s.source   = { :git => 'https://github.com/oyh5233/OOModel.git',
:tag => "#{s.version}" }

s.description = 'single,synchronous and thread safety model in memory and in database,support json mapping.concise api to use.'

s.requires_arc   = true

s.preserve_paths = 'README.md', 'Classes/OOModel.swift', 'Framework/Lumberjack/CocoaLumberjack.modulemap'
s.ios.deployment_target = '5.0'
s.osx.deployment_target = '10.7'
s.watchos.deployment_target = '2.0'
s.tvos.deployment_target = '9.0'

s.default_subspecs = 'Default'

s.subspec 'Default' do |ss|
ss.source_files = 'Classes/*.{h,m}'
end

s.subspec 'Swift' do |ss|
ss.ios.deployment_target = '8.0'
ss.source_files = 'Classes/OOModel.swift'
#ss.osx.deployment_target = '10.10'
#ss.watchos.deployment_target = '2.0'
#ss.tvos.deployment_target = '9.0'
#ss.dependency 'CocoaLumberjack/Extensions'
end

end