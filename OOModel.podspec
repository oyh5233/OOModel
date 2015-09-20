Pod::Spec.new do |s|
  s.name = 'OOModel'
  s.version = '0.1'
  s.summary = 'super model based mantle,auto use FMDB to storage and update.'
  s.authors = {'oyh5233' => 'oyh5233@qq.com'}
  s.license = { 
    :type => 'MIT', 
    :text => <<-LIC
This code is licensed under the MIT License:

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
LIC
  }
  s.source = { :git => 'https://github.com/oyh5233/OOModel.git', :tag => "RNCryptor-#{s.version.to_s}" }
  s.description = 'super model based mantle,auto use FMDB to storage and update.'
  s.homepage = 'https://github.com/oyh5233/OOModel'
  s.source_files = 'OOModel/*.{h,m}'
  s.public_header_files = 'OOModel/*.h'
  s.requires_arc = true
  s.ios.deployment_target = '7.0'
end

