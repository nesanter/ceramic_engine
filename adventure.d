import engine;
import std.stdio, std.math;
import std.random;

void main() {
    
	Engine.run("Test", 1920, 1080, new TestWorld);
    
}

struct Location {
    long x, y;
}

class TestWorld : World {
    
    ulong light_id;
    bool up = false;
    float atten = 1;
    float atten_max = 10;
    float atten_min = 0.01;

    Timer myTimer;
    
    WorldObject[Location] objects;
    //PhysicsObject[] physics_objects;
    
    Character player;

    bool key_left_down, key_right_down,
         key_up_down, key_down_down;

    void create_event() {
        
//        Engine.enable_cursor(false);
//        Engine.track_mouse = true;
 
        light_id = Renderer.create_light([0,0,0], [1,1,1], 1, true);

        player = new Character;
        player.set_translation([0,0,5]);
       
        objects[Location(0,0)] = player;

        writeln("Create world");
        myTimer = create_timer(0.01);    
    }
    
    void destroy_event() {
        writeln("Destroy world");
    }
    
    void key_event(int key, int scancode, int action, int mods) {
        if (key == GLFW_KEY_ESCAPE)
            Engine.stop();
            
        if (action == GLFW_RELEASE) {
            switch (key) {
                case GLFW_KEY_LEFT:
                    key_left_down = false;
                    break;
                case GLFW_KEY_RIGHT:
                    key_right_down = false;
                    break;
                case GLFW_KEY_UP:
                    key_up_down = false;
                    break;
                case GLFW_KEY_DOWN:
                    key_down_down = false;
                    break;
                default:
                    break;
            }
        } else if (action == GLFW_PRESS) {
            switch (key) {
                case GLFW_KEY_LEFT:
                    key_left_down = true;
                    break;
                case GLFW_KEY_RIGHT:
                    key_right_down = true;
                    break;
                case GLFW_KEY_UP:
                    key_up_down = true;
                    break;
                case GLFW_KEY_DOWN:
                    key_down_down = true;
                    break;
                default:
                    break;
            }
        }
    }
    
    bool timer_event(Timer t) {
        if (up) {
            atten += 0.01;
            if (atten >= atten_max)
                up = false;
        } else {
            atten -= 0.01;
            if (atten <= atten_min)
                up = true;
        }
//        writeln(atten);
        Renderer.replace_light(0, [0,0,0], [1,1,1], atten, true);
        if (key_left_down)
            player.turn_left();
        if (key_right_down)
            player.turn_right();
        if (key_up_down)
            player.forward();
        if (key_down_down)
            player.backward();

        return true;
    }
    
    WorldObject[] get_objects() {
        return objects.values;
    }
    /*
    PhysicsObject[] get_physics_objects() {
        return physics_objects;
    }
    */
}

class Character : WorldObjectGL {
    this() {
        Mesh m = new Mesh;
        rdata = prism(4, 0.5, 2, [0,0,1], m);
    }

    void create_event() {

    }

    void destroy_event() {

    }

    bool timer_event(Timer t) {
        return false;
    }

    void turn_left() {
        rotate([0,1,0],0.05);
    }

    void turn_right() {
        rotate([0,1,0],-0.05);
    }

    void forward() {
        move(0.1);
    }

    void backward() {
        move(-0.1);
    }
}


class TestPrism : WorldObjectGL {
    
    double i1, i2, i3;
    
    this() {
        
        Mesh m = new Mesh;
        
        rdata = prism(3/*uniform(3,12)*/, uniform(0.5,1.0), uniform(.25,2.0), [uniform(0.0,1.0),uniform(0.0,1.0),uniform(0.0,1.0)], m);
        //rdata = prism(6,1,2,[1,1,1],m);
        i1 = uniform(0.0001, 0.001);
        i2 = uniform(0.0001, 0.001);
        i3 = uniform(0.0001, 0.001);
        //create_timer(uniform(0.001,0.02));
        
        refraction_index = uniform(0.1,2.0);
        
        //translation = [0,0,0];
        //rotation = ZeroQuaternion;
        
        //writeln("here");
        //pobjs ~= new PhysicsObject(m, GeometryType.Trimesh, 1, true, translation, cast(float[4])rotation);
        
        //init_physics(m, GeometryType.Trimesh, 1.0, true);
        
        //pobjs ~= this;
        

        
        
    }
    
    void create_event() {
        writeln("Object created!");
    }
    
    void destroy_event() {
        writeln("Object destroyed!");
    }
    
    bool timer_event(Timer t) {
        //writeln("Timer triggered on object!");
        
        //rotate([1,0,0],0.001);
        //rotate([0,1,0],0.002);
        //rotate([0,0,1],0.003);
        
        return true;
    }
}

class TestLO : WorldObjectGL {
        
    
    float[3] delta;
    ulong q = 0;
    
    ulong id;
    this() {
        rdata = prism(50, 0.05, 0.1, [1,1,1], null);
        id = Renderer.create_light([0,0,0],[uniform(0.75,1),uniform(0.75,1),uniform(0.75,1)], 5, true);
        writeln("ID=",id);
        create_timer(0.01);
    }
    
    void create_event() {
        writeln("Object created!");
    }
    
    void destroy_event() {
        writeln("Object destroyed!");
    }
    
    bool timer_event(Timer t) {
        //writeln("Timer triggered on object!");
        
        if (q == 0) {
            float[3] p = [uniform(-4,4),uniform(-3,3),uniform(-8,8)];
            delta = (p[] - Renderer.lights[id].position[]) / 500;
            q = 250;
        } else {
            q--;
        }
        Renderer.lights[id].position[] += delta[];
        
        
        set_translation(Renderer.lights[id].position);
        return true;
    }
}

class TestPlane : WorldObjectGL {
    
    this() {
        
        Mesh m = new Mesh;
        
        rdata = xyplane(8,8,[1,1,1], m);
        refraction_index = 0;
        
        //init_physics(m, GeometryType.Trimesh, 1, false);
    }
    
    void create_event() {
        writeln("Object created!");
    }
    
    void destroy_event() {
        writeln("Object destroyed!");
    }
    
    bool timer_event(Timer t) {
        //writeln("Timer triggered on object!");
        return false;
    }
}

class TestBigPlane : WorldObjectGL {
    this() {
        
        Mesh m = new Mesh;
        
        rdata = xyplane(1,1,[1,1,1],m);
        refraction_index = 0;
        
        //init_physics(m, GeometryType.Trimesh, 1, false);
    }
    
    void create_event() {
        writeln("Object created!");
    }
    
    void destroy_event() {
        writeln("Object destroyed!");
    }
    
    bool timer_event(Timer t) {
        //writeln("Timer triggered on object!");
        return false;
    }
}


RenderDataIndexed prism(int sides, float radius, float length, float[3] color, Mesh m) {
	Vertex[] vertices;
	ushort[] indices;
	vertices ~= [new Vertex([0,0,-length/2], color), new Vertex([0,0,length/2], color)];
	float rcoss,rsins;
	foreach (float s; 0 .. sides) {
		rcoss = radius * cos(2*(s/sides)*PI);
		rsins = radius * sin(2*(s/sides)*PI);
		vertices ~= [
						new Vertex([rcoss, rsins, -length/2], color),
						new Vertex([rcoss, rsins, length/2], color),
						new Vertex([rcoss, rsins, -length/2], color),
						new Vertex([rcoss, rsins, length/2], color)
					];
		if (s == 0) {
			indices ~= cast(ushort[])[s*4+2, 0, (sides-1)*4+2, 1, s*4+3, (sides-1)*4+3]; 
		} else {
			indices ~= cast(ushort[])[s*4+2, 0, (s-1)*4+2, 1, s*4+3, (s-1)*4+3];
		}
		if (s == 0) {
			indices ~= cast(ushort[])[s*4+4, (sides-1)*4+4, s*4+5];
			indices ~= cast(ushort[])[(sides-1)*4+5, s*4+5, (sides-1)*4+4];
		} else {
			indices ~= cast(ushort[])[s*4+4, (s-1)*4+4, s*4+5];
			indices ~= cast(ushort[])[(s-1)*4+5, s*4+5, (s-1)*4+4];
		}
	}
	//foreach (v; vertices) {
	//	writeln(v.position);
	//	writeln(v.normal);
	//}
    
    if (m !is null) {
        m.indexData = indices;
        foreach (v; vertices) {
            m.vertexData ~= v.position;
            //m.vertexData ~= [0.0];
        }
    }
    
	generate_normals(vertices, indices);
	return new RenderDataIndexed(vertices, indices, PrimitiveType.Triangles, VertexTemplate([VA.Vec3, VA.Vec3, VA.Vec3]));
}

/*
RenderDataIndexed prism(int sides, float radius, float length, float[3] color, Mesh m) {
	Vertex[] vertices;
	ushort[] indices;
	vertices ~= [new Vertex([0,0,-length/2], color), new Vertex([0,0,length/2], color)];
	float rcoss,rsins;
	foreach (float s; 0 .. sides) {
		rcoss = radius * cos(2*(s/sides)*PI);
		rsins = radius * sin(2*(s/sides)*PI);
		vertices ~= [
						new Vertex([rcoss, rsins, -length/2], color),
						new Vertex([rcoss, rsins, length/2], color),
						//new Vertex([rcoss, rsins, -length/2], color),
						//new Vertex([rcoss, rsins, length/2], color)
					];
                    
        
        //add front/back triangles
		if (s == 0) {
			indices ~= cast(ushort[])[s*2+2, 0, (sides-1)*2+2, 1, s*2+3, (sides-1)*2+3]; 
		} else {
			indices ~= cast(ushort[])[s*2+2, 0, (s-1)*2+2, 1, s*2+3, (s-1)*2+3];
		}
		
        //add side triangles
        if (s == 0) {
			indices ~= cast(ushort[])[s*2+2, (sides-1)*2+2, s*2+3];
			indices ~= cast(ushort[])[(sides-1)*2+3, s*2+3, (sides-1)*2+2];
		} else {
			indices ~= cast(ushort[])[s*2+2, (s-1)*2+2, s*2+3];
			indices ~= cast(ushort[])[(s-1)*2+3, s*2+3, (s-1)*2+2];
		}
        
	}
	//foreach (v; vertices) {
	//	writeln(v.position);
	//	writeln(v.normal);
	//}
    
    if (m !is null) {
        m.indexData = indices;
        foreach (v; vertices) {
            m.vertexData ~= v.position;
        }
    }
    
	generate_normals(vertices, indices);
	return new RenderDataIndexed(vertices, indices, PrimitiveType.Triangles, VertexTemplate([VA.Vec3, VA.Vec3, VA.Vec3]));
}
*/

RenderDataIndexed xyplane(float w, float h, float[3] color, Mesh m) {
	Vertex[] vertices;
	ushort[] indices;
	vertices ~= [
			new Vertex([-w/2, -h/2, 0], color, [0,0,1]),
			new Vertex([-w/2,  h/2, 0], color, [0,0,1]),
			new Vertex([ w/2,  h/2, 0], color, [0,0,1]),
			new Vertex([ w/2, -h/2, 0], color, [0,0,1])
		];
	indices ~= [
			0, 1, 2,
			2, 3, 0
		];
    
    if (m !is null) {
        m.indexData = indices;
        foreach (v; vertices) {
            m.vertexData ~= v.position;
        }
    }
    
	//generate_normals(vertices, indices);
	return new RenderDataIndexed(vertices, indices, PrimitiveType.Triangles);
}
/*
RenderDataIndexed xyplane2(float w, float h, float[3] color, Mesh m) {
	Vertex[] vertices;
	ushort[] indices;
    ushort i = 0;
    const float N = 10;
    foreach (x; -w/N .. w/N) {
        foreach (y; -h/N .. h/N) {
        vertices ~= [
                new Vertex([x-(w/N), y-(h/N), 0], color, [0,0,1]),
                new Vertex([x-(w/N), y, 0], color, [0,0,1]),
                new Vertex([x, y, 0], color, [0,0,1]),
                new Vertex([x, y-(h/N), 0], color, [0,0,1]),
            ];
        }
        indices ~= cast(ushort[])[
			i*4+0, i*4+1, i*4+2,
			i*4+2, i*4+3, i*4+0
		];
        i++;
    }
	
    
    if (m !is null) {
        m.indexData = indices;
        foreach (v; vertices) {
            m.vertexData ~= v.position;
        }
    }
    
	//generate_normals(vertices, indices);
	return new RenderDataIndexed(vertices, indices, PrimitiveType.Triangles);
}
*/
