function PostExtract(fields, tables, ctx)
    if fields._InvoiceSubtotal then
        fields.InvoiceSubtotal = CastToDecimal(fields._InvoiceSubtotal.Text, ctx)
    end
    if fields._InvoiceTotal then
        fields.InvoiceTotal = CastToDecimal(fields._InvoiceTotal.Text, ctx)
    end
    if fields._InvoiceTax then
        fields.InvoiceTax = CastToDecimal(fields._InvoiceTax.Text, ctx)
    end
    if fields._Anchor0 then
        local text = ctx['text']
        text = text:GetArea(
                text.BBox.Left,
                fields._Anchor0.BBox.Bottom,
                fields._Anchor0.BBox.Right,
                text.BBox.Bottom
        )
        if text.Length > 0 then
            fields.CustomerName = text[0]:ToString()
        end
    end
end
function CastToDecimal(str, ctx)
    local decimal = str:gsub('%,+', ''):match('%d+%.%d%d')
    return ctx:CreateDecimal(decimal) or nil
end
function Finalize(fields, tables, ctx)
    if tables.LineItems then
        local items = tables.LineItems
        local vehicleSum = ''
        local descriptionSum = ''
        for i = items.Length - 1, 0, -1 do
            local extraLines = items[i].ContractVehicle.Text:match('Type[%s%:]+') or items[i].ContractVehicle.Text:match('ORIX%s+TAX') or items[i].Description.Text:match('Total%s+of%s+Cost%s+Centre')
            local underDates = ''
            if items[i].StartDate.Value then
                local startDate = ctx:CreateDate(items[i].StartDate.Text, 'dd/mm/yyyy') or nil
                if not startDate then
                    underDates = underDates .. ' ' .. items[i].StartDate.Text .. ' '
                end
                items[i].StartDate = startDate
            end
            if items[i].TransDate.Value then
                local transDate = ctx:CreateDate(items[i].TransDate.Text, 'dd/mm/yyyy') or nil
                if not transDate then
                    underDates = underDates .. items[i].TransDate.Text .. ' '
                end
                items[i].TransDate = transDate
            end
            if items[i].ContractVehicle.Value then
                local driver = items[i].Driver.Value and ' ' .. items[i].Driver.Text or ''
                items[i].ContractVehicle = items[i].ContractVehicle.Text .. driver .. underDates
            end
            if extraLines then
                items:RemoveRow(i)
            end
        end
        for i = items.Length-1, 0, -1 do
            if not items[i].Total.Value then
                descriptionSum = items[i].Description.Value and (items[i].Description.Text .. ' ' .. descriptionSum) or descriptionSum
                vehicleSum = items[i].ContractVehicle.Value and (items[i].ContractVehicle.Text .. ' ' .. vehicleSum) or vehicleSum
                items:RemoveRow(i)
            else
                items[i].ContractVehicle = items[i].ContractVehicle.Value and (items[i].ContractVehicle.Text .. ' ' .. vehicleSum) or vehicleSum
                items[i].Description = items[i].Description.Value and (items[i].Description.Text .. ' ' .. descriptionSum) or descriptionSum
                vehicleSum = ''
                descriptionSum = ''
            end
        end
    end
end