function PostExtract(fields, tables, ctx)
    if fields.Trade and fields.Subcontractor and not fields.WorkOrderRefNo then
        fields.WorkOrderRefNo = fields.Subcontractor.Text .. ' ' .. fields.Trade.Text
    end
end
local d
function Finalize(fields, tables, ctx)
    if tables.LineItems then
        local tableDelimiter
        local items = tables.LineItems
        for i = 0, tables.LineItems.Length - 1 do
            local item = tables.LineItems[i]
            local s = string.gsub(string.lower(item.Description.Text), '%W+', '')
            if string.find(s, 'contractwork', 1, true) then
                fields.CertificationOriginalContractValue = fields.SubContractWorkTotal or item.Accumulative.Value
            end
            if string.find(s, 'additionalwork', 1, true) then
                fields.CertificationVariationsValue = fields.AdditionalWorkTotal or item.Accumulative.Value
            end
            if string.find(s, 'subtotal', 1, true) and not tableDelimiter then
                tableDelimiter = i
            end
        end
        if tableDelimiter then
            for i = items.Length - 1, tableDelimiter + 1, -1 do
                items:RemoveRow(i)
            end
        end
    end
    if not fields.WorkOrderRefNo then
        fields.WorkOrderRefNo = 'NA'
    end
    if tables.AppendixA then
        for i = 0, tables.AppendixA.Length - 1 do
            local item = tables.AppendixA[i]
            local s = string.gsub(string.lower(item.Description.Text), '[^a-z]+', '')
            if string.find(s, 'subtotalcontractworksforwarded', 1, true) then
                fields.OriginalContractValue = item.Amount.Value
                fields.ActivityCodeOriginalContract = item.Amount.Value
            end
            if string.find(s, 'subtotaladditionalworksforwarded', 1, true) then
                fields.VariationsValue = item.Amount.Value
                fields.ActivityCodeVariations = item.Amount.Value
            end
        end
        tables.AppendixA = nil
    end
    if tables.AppendixB then
        for i = tables.AppendixB.Length - 1, 0, -1 do
            local item = tables.AppendixB[i]
            if item.Certified.Value or item.AfterRetention.Value or item.Payment.Value then
                fields.NumOfCertificates = item.Code.Value
                break
            end
        end
        tables.AppendixB = nil
    end
end