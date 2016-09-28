class TestRepository
  attr_accessor :data

  def initialize(data = {})
    self.data = data
  end

  def all
    data.values
  end

  def [](id)
    data[id]
  end

  def push(obj)
    obj.id = data.values.length.next
    data[obj.id] = obj
  end

  def update(obj)
    data[obj.id] = obj
  end

  def delete(obj)
    data.delete(obj.id)
  end
end
