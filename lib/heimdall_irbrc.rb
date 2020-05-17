env = ENV['HEIMDALL_ENV'] || 'local'
color = {
  'local' => [:bold],
  'dev' => [:cyan, :bold],
  'staging' => [:yellow, :bold],
  'production' => [:red, :bold]
}.fetch(env)

IRB.conf[:PROMPT][:HEIMDALL] = IRB.conf[:PROMPT][:DEFAULT].merge({
  PROMPT_I: "#{Paint["heimdall (#{env}) %n:%i>", *color]} ",
  PROMPT_N: "#{Paint["heimdall (#{env}) %n:%i>", *color]} ",
  PROMPT_S: "#{Paint["heimdall (#{env}) %n:%i%l", *color]} ",
  PROMPT_C: "#{Paint["heimdall (#{env}) %n:%i*", *color]} "
})
IRB.conf[:PROMPT_MODE] = :HEIMDALL
