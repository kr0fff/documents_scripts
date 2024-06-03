function ToAlphanumeric(str)
    str = str:gsub('[%[%]%*]+', '')
    local strSum = ''
    for sub in str:gmatch('[%a%p%d]+') do
        if sub then
            local subStart, subEnd = str:find(sub)
            strSum = strSum .. sub
            if subStart and subEnd and subEnd < #str then
                strSum = strSum .. ' '
            end
        end
    end
    if string.len(strSum) > 0 then
        return strSum
    else
        return nil
    end
end