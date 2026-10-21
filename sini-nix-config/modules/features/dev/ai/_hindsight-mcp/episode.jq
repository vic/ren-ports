def strip_injected:
  gsub("<(hook_prompt|task-notification|system-reminder|local-command-stdout|command-name|command-message|command-args|hindsight_memories|hindsight_bank|relevant_memories)\\b[\\s\\S]*?</(hook_prompt|task-notification|system-reminder|local-command-stdout|command-name|command-message|command-args|hindsight_memories|hindsight_bank|relevant_memories)>"; "");

def action_line:
  . as $b
  | ($b.input // {}) as $i
  | ( [ $i.file_path?, $i.path?, $i.notebook_path?, $i.command?, $i.pattern?, $i.query?, $i.url?, $i.name?, $i.id? ]
      | map(select(type == "string" and (. | gsub("^\\s+|\\s+$"; "")) != ""))
      | first ) as $t
  | if $t == null then $b.name
    else ($t | split("\n")[0] | .[0:100]) as $s | "\($b.name) \($s)"
    end;

select(.type == "user" or .type == "assistant")
| select(.isMeta != true and .isSidechain != true and .isCompactSummary != true)
| select(.message | type == "object")
| . as $line
| ($line.message.content) as $c
| ( if ($c | type) == "string" then
      [ { role: $line.type, content: ($c | strip_injected) } ]
    elif ($c | type) == "array" then
      ( [ $c[] | select(type == "object" and .type == "text" and (.text | type) == "string")
          | .text | strip_injected ]
        | map(select(gsub("^\\s+|\\s+$"; "") != ""))
        | join("\n") ) as $prose
      | ( if ($prose | gsub("^\\s+|\\s+$"; "")) != "" then [ { role: $line.type, content: $prose } ] else [] end )
        + [ $c[] | select(type == "object" and .type == "tool_use" and (.name | type) == "string")
            | { role: "action", content: action_line } ]
    else [] end ) as $turns
| $turns[]
| select((.content | gsub("^\\s+|\\s+$"; "")) != "")
| .content |= gsub("^\\s+|\\s+$"; "")
| if .role == "user" and (.content | test("<teammate-message")) then .role = "peer" else . end
| if ($line.timestamp | type) == "string" then . + { timestamp: $line.timestamp } else . end
