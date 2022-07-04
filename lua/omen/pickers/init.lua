local pickers = {}

---@alias DisplayFormatter fun(file: string): string

---@alias SelectCallback fun(file: string)

---@class OmenPicker
---@field pick fun(data: PickData)

---@class PickData
---@field title string @Title to be displayed in the picker
---@fjeld get_files fun():string[] @Function that returns the list of password files
---@field formatter DisplayFormatter @Formatter for file entries
---@field on_selected SelectCallback @Callback when the entry is selected

---Returns the picker module thats name given
---@param picker PickerType
---@return OmenPicker
function pickers.get(picker)
  return require("omen.pickers." .. picker)
end

---Pick with given picker name
---@param picker PickerType
---@param data PickData
function pickers.pick(picker, data)
  pickers.get(picker).pick(data)
end

return pickers
