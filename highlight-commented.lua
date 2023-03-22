-- This function processes an array of inline elements (text spans)
-- and applies custom markup rules by searching for opening and closing patterns.
function Inlines(inlines)
    -- 'result' will store the final processed inline elements
    local result = pandoc.Inlines {}

    -- 'markup' will temporarily store the text found between opening and closing patterns
    local markup = nil

    -- 'start' will store the position of the opening pattern in the input text
    local start = nil

    -- Iterate over the input array of inline elements
    for i, inline in ipairs(inlines) do
        -- Check if the current inline element is a text string
        if inline.tag == 'Str' then
            -- If the markup variable is not initialized, search for the opening pattern in the text
            if not markup then
                -- Look for the opening pattern at the beginning of the inline text
                local first = inline.text:match('^' .. opening .. '(.*)')
                if first then
                    -- Store the current inline element as the start of the markup section
                    start = inline

                    -- Check if the closing pattern is already present in the current string
                    local selfclosing = first:match('(.*)' .. closing .. '$')
                    if selfclosing then
                        -- If it is, treat this as a self-closing markup and add the processed text
                        -- to the result
                        result:insert(markup_inlines { pandoc.Str(selfclosing) })
                    elseif nospace and first == '' and is_space(inlines[i + 1]) then
                        -- If the opening pattern is followed by a space, and the config disallows
                        -- spaces, add the original inline element to the result
                        result:insert(inline)
                    else
                        -- Otherwise, start collecting the text in the markup variable
                        markup = pandoc.Inlines { pandoc.Str(first) }
                    end
                else
                    -- If no opening pattern is found, add the original inline element to the result
                    result:insert(inline)
                end
            else
                -- If the markup variable is initialized, search for the closing pattern
                local last = inline.text:match('(.*)' .. closing .. '$')
                if last then
                    -- If the closing pattern is found, add the remaining text to the markup
                    markup:insert(pandoc.Str(last))

                    -- Process the markup and add it to the result
                    result:insert(markup_inlines(markup))

                    -- Clear the markup variable
                    markup = nil
                else
                    -- If no closing pattern is found, continue collecting text in the markup
                    markup:insert(inline)
                end
            end
        else
            -- If the inline element is not a text string, add it to either the markup or result,
            -- depending on the current state
            local acc = markup or result
            acc:insert(inline)
        end
    end

    -- If there is unterminated markup (i.e., an opening pattern without a closing pattern), add the
    -- original unprocessed text to the result
    if markup then
        markup:remove(1) -- Remove the stripped-down first element
        result:insert(start)
        result:extend(markup)
    end

    -- Return the final processed array of inline elements
    return result
end
