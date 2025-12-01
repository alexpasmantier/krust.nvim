local krust = require("krust")

describe("krust", function()
  it("exposes render function", function()
    assert.is_function(krust.render)
  end)
end)
