local grouping = dofile('CustomLRStacking.lrdevplugin/plugin/core/grouping.lua')

describe('grouping', function()
  local opts = grouping.defaultOptions()

  local function entry(fileName, folder)
    return { fileName = fileName, folder = folder or '/photos' }
  end

  describe('identify', function()
    it('pairs jpg and raw with the same stem', function()
      local groups, singles = grouping.identify({
        entry('IMG_1234.arw'),
        entry('IMG_1234.jpg'),
      }, opts)
      assert.are.equal(1, #groups)
      assert.are.equal(0, #singles)
      assert.are.equal(2, #groups[1])
    end)

    it('skips photos without a pair', function()
      local groups, singles = grouping.identify({
        entry('IMG_1234.arw'),
        entry('IMG_1234.jpg'),
        entry('IMG_9999.arw'),
      }, opts)
      assert.are.equal(1, #groups)
      assert.are.equal(1, #singles)
    end)

    it('is case-insensitive on stem and extension', function()
      local groups = grouping.identify({
        entry('img_1234.ARW'),
        entry('IMG_1234.JPG'),
      }, opts)
      assert.are.equal(1, #groups)
    end)

    it('does not group same-extension files (jpg + jpeg)', function()
      local groups, singles = grouping.identify({
        entry('IMG_1234.jpg'),
        entry('IMG_1234.jpeg'),
      }, opts)
      assert.are.equal(0, #groups)
      assert.are.equal(2, #singles)
    end)

    it('does not group across folders', function()
      local groups, singles = grouping.identify({
        entry('IMG_1234.arw', '/a'),
        entry('IMG_1234.jpg', '/b'),
      }, opts)
      assert.are.equal(0, #groups)
      assert.are.equal(2, #singles)
    end)

    it('requires at least one raw member', function()
      local groups = grouping.identify({
        entry('IMG_1234.jpg'),
        entry('IMG_1234.tif'),
      }, opts)
      assert.are.equal(0, #groups)
    end)

    it('groups dng + arw (both raw, distinct extensions)', function()
      local groups = grouping.identify({
        entry('IMG_1234.arw'),
        entry('IMG_1234.dng'),
      }, opts)
      assert.are.equal(1, #groups)
    end)
  end)

  describe('choosePrimary', function()
    it('picks raw by default', function()
      local group = { entry('IMG_1234.jpg'), entry('IMG_1234.arw') }
      local primary = grouping.choosePrimary(group, opts)
      assert.are.equal('IMG_1234.arw', primary.fileName)
    end)

    it('picks jpg when jpg_first', function()
      local group = { entry('IMG_1234.arw'), entry('IMG_1234.jpg') }
      local o = {
        top_of_stack = 'jpg_first',
        raw_extensions = opts.raw_extensions,
        jpg_extensions = opts.jpg_extensions,
      }
      local primary = grouping.choosePrimary(group, o)
      assert.are.equal('IMG_1234.jpg', primary.fileName)
    end)
  end)
end)
