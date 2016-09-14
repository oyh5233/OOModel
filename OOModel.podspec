Pod::Spec.new do |s|

s.name     = 'OOModel'
s.version  = '0.1.3'
s.license  = 'MIT'
s.summary  = 'A fast model framework in memory and in database'
s.homepage = 'https://github.com/oyh5233/OOModel'
s.author   = { 'oyh5233' => 'oyh5233@outlook.com' }
s.source   = { :git => 'https://github.com/oyh5233/OOModel.git',
:tag => "#{s.version}" }

s.description = 'single,synchronous and thread safety model in memory and in database,support json mapping.concise api to use.'

s.requires_arc   = true

s.ios.deployment_target = '7.0'

s.source_files = 'OOModel/Classes/*.{h,m}'
s.libraries = 'sqlite3'
 s.xcconfig = {
      'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
    }
end
