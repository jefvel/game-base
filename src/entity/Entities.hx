package entity;

class Entities {
    static var instance : Entities;
    public static inline function getInstance() {
        return instance;
    }

    var entities : Array<Entity>;

    public function new() {
        instance = this;
        entities = [];
    }

    function add(e: entity.Entity) {
        entities.push(e);
    }

    function remove(e: entity.Entity) {
        entities.remove(e);
    }

    public function update(dt : Float) {
        for (e in entities) {
            e.update(dt);
        }
    }
}