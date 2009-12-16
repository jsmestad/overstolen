require 'over_stolen'

use Warden::Manager do |manager|
  manager.default_strategies :twitter
  manager.failure_app = OverStolen::App
end

run OverStolen::App