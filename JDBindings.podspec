Pod::Spec.new do |s|
  s.name         = "JDBindings"
  s.version      = "0.1.1"
  s.summary      = "Class extensions for NSObject for easier KVO and bindings."
  s.description  = <<-DESC
                   Class extensions for NSObject for easier KVO and bindings.
                   DESC
  s.homepage     = "https://github.com/johannesd/JDBindings.git"
  s.license      = { 
    :type => 'Custom permissive license',
    :text => <<-LICENSE
          Free for commercial use and redistribution. No warranty.

        	Johannes Dörr
        	mail@johannesdoerr.de
    LICENSE
  }
  s.author       = { "Johannes Doerr" => "mail@johannesdoerr.de" }
  s.source       = { :git => "https://github.com/johannesd/JDBindings.git", :tag => "0.1.1" }
  s.platform     = :ios, '8.0'
  s.source_files  = '*.{h,m}'
  s.exclude_files = 'Classes/Exclude'
  s.requires_arc = true
end
