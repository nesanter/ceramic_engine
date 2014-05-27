import std.stdio;
import std.conv;

protected import derelict.opengl3.gl;
public import derelict.glfw3.glfw3;

public import renderer;

class EngineException : Exception {
	uint err;
	this(string msg, uint e = 0) {
		err = e;
		super(msg);
	}
}

abstract class Engine {
	static this() {
		DerelictGL3.load();
		DerelictGLFW3.load();
	}
	
	static ~this() {
		if (init)
			glfwTerminate();
	}
	
	static GLFWwindow* window;
	
	static uint width, height;
	
	private static bool init;
	
	static GLVersion gl_version_loaded;
	
	private static bool running;
	
	static Exception error;
    
    static World world;
    
    static Timer[] timers;
    static double time, elapsed_time;
    
    static bool track_mouse;
    static double[2] cursor_xy = [0,0];
    static private double[2] cursor_acc_delta = [0,0];
    
	static void run(string title, uint w, uint h, World world, RenderConfig config = DefaultRenderConfig) {
		this.width = w;
		this.height = h;
        
        this.world = world;
				
		if (!init) {
			if (!glfwInit())
				throw new EngineException("glfwInit()");
			init = true;
		}
		
		glfwSetErrorCallback(&engine_err_callback);
		
		window = glfwCreateWindow(w, h, title.ptr, glfwGetPrimaryMonitor(), null);
		
		if (window is null) {
			throw new EngineException("glfwCreateWindow()");
		}
		
		glfwSetKeyCallback(window, &engine_key_callback);
		
		glfwMakeContextCurrent(window);
		
		gl_version_loaded = DerelictGL3.reload();
		
		writeln(gl_version_loaded);
        
        if (!Renderer.init) {
            if (!Renderer.initialize(config))
                throw new EngineException("Render.initialize()");
        }
		
		running = true;
		
        glfwSwapInterval(-2);
        
        time = glfwGetTime();
        
        world.create_event();
        
		while (!glfwWindowShouldClose(window) && running) {
            
            double new_time = glfwGetTime();
            elapsed_time = new_time-time;
            time = new_time;
            
            if (track_mouse) {
                double[2] new_xy;
                glfwGetCursorPos(window, &new_xy[0], &new_xy[1]);
                cursor_acc_delta[] += new_xy[] - cursor_xy[];
                cursor_xy = new_xy;
            }
            
            foreach (i,t; timers.dup) {
                if (t.time <= time) {
                    if (t.owner.timer_event(t))
                        t.time += t.period;
                    else
                        timers = timers[0..i]~timers[i+1..$];
                }
            }
            
            Renderer.clear();
            world.render();
            
            glfwSwapBuffers(window);
            
			glfwPollEvents();
			
			if (error !is null)
				throw error;
		}
		
        world.destroy_event();
        
		glfwDestroyWindow(window);
		
	}
	
	static void stop() {
		running = false;
	}
    
    static void enable_cursor(bool enabled) {
        glfwSetInputMode(window, GLFW_CURSOR, enabled ? GLFW_CURSOR_NORMAL : GLFW_CURSOR_DISABLED);
    }
    
    @property static double[2] cursor_delta() {
        double[2] delta = cursor_acc_delta;
        cursor_acc_delta = [0,0];
        return delta;
    }
    
    static void cursor_reset() {
        glfwSetCursorPos(window, 0, 0);
    }
    
}

class Timer {
    double period;
    double time;
    Actor owner;
    
    this(double period, Actor owner) {
        this.period = period;
        time = Engine.time + period;
        this.owner = owner;
    }
}

extern (C) void engine_err_callback(int err, const(char)* desc) nothrow {
	try {
		Engine.error = new EngineException(to!string(desc), err);
	} catch (Exception e) {
		Engine.error = e;
	}
}

extern (C) void engine_key_callback(GLFWwindow* win, int key, int scancode, int action, int mods) nothrow {
    
    try {
        Engine.world.key_event(key, scancode, action, mods);
    } catch (Exception e) {
        Engine.error = e;
    }

}

interface Actor {
    void create_event();
    void destroy_event();
    bool timer_event(Timer t);
}

interface _World : Actor {
    void render();
    WorldObject[] get_objects();
    void key_event(int key, int scancode, int action, int mods);
}

interface _WorldObject : Actor {
    void render();
}

abstract class World : _World {
    final Timer create_timer(double period) {
        Timer t = new Timer(period, this);
        Engine.timers ~= t;
        return t;
    }
    
    void render() {
        foreach (obj; get_objects()) {
            obj.render();
        }
    }
}

abstract class WorldObject : _WorldObject {
    final Timer create_timer(double period) {
        Timer t = new Timer(period, this);
        Engine.timers ~= t;
        return t;
    }
    
    void render() {
        //do nothing
    }
}
