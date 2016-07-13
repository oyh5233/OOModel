Pod::Spec.new do |s|

s.name     = 'OOModel'
s.version  = '0.0.8'
s.license  = 'MIT'
s.summary  = 'A fast && useful json model framework'
s.homepage = 'https://github.com/oyh5233/OOModel'
s.author   = { 'oyh5233' => 'oyh5233@outlook.com' }
s.source   = { :git => 'https://github.com/oyh5233/OOModel.git',
:tag => "#{s.version}" }

s.description = 'single,synchronous and thread safety model in memory and in database,support json mapping.concise api to use.'

s.requires_arc   = true

s.ios.deployment_target = '7.0'
s.watchos.deployment_target = '2.0'

s.default_subspecs = 'Default'

s.subspec 'Default' do |ss|
ss.source_files = 'OOModel/Classes/*.{h,m}'
end

end