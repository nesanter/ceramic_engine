import std.stdio;
import engine, quaternion;
import std.conv, std.math;

alias float[16] mat4;
const ZeroQuaternion = Quaternion(1,0,0,0);

enum DefaultRenderConfig = RenderConfig("misc/default_vertex_shader.glsl","misc/default_fragment_shader.glsl", true, true, true, true);

struct RenderConfig {
    string vsfname, fsfname;
    bool perspective;
    bool basic_lighting;
    bool advanced_lighting;
    bool mirrors;
}

abstract class Renderer {
    
    struct Light {
        float[3] position;
        float[3] color;
        float attenuation;
        bool enabled;
        //int type;
        //float[3] direction;
    }
    
    private static GLProgram program;
    
    static bool init;
    static RenderConfig config;
    
    enum string[] perspective_uniforms = [
            "perspectiveMatrix",
            "rotationMatrix",
            "translationMatrix",
            //"rawTranslationMatrix",
            //"rawRotationMatrix"
        ];
    enum string[] basic_lighting_uniforms = [
            "lightPos",
            "lightColor",
            //"lightType",
            //"lightFaceDir"
        ];
    enum string[] advanced_lighting_uniforms = [
            "lightAttenuation",
            "specularColor",
            "roughnessValue",
            "refIndex"
        ];
    
    enum string[] mirror_uniforms = [
    
    ];
    
    public {
        static float frustum_scale = 4.0;
        static float z_near = 1.0;
        static float z_far = 300.0;
        
        static mat4 perspectiveMatrix;
        
        static Quaternion global_rotation = (cast(Quaternion)ZeroQuaternion).opposite();
        static Quaternion inverse_rotation = ZeroQuaternion;
        static float[3] global_offset = [0, 0, 0];
    }
    static Light[] lights;
    
    static bool initialize(RenderConfig config) {
        this.config = config;
        
        try {
            auto vsfile = File(config.vsfname, "r");
            
            string vscode;
            foreach (ln; vsfile.byLine)
                vscode ~= ln ~ "\n";
            
            vsfile.close();
            
            auto fsfile = File(config.fsfname, "r");
            
            string fscode;
            foreach (ln; fsfile.byLine)
                fscode ~= ln ~ "\n";
                
                
            string[] uniforms;
            
            if (config.perspective)
                uniforms ~= perspective_uniforms;
            
            if (config.basic_lighting)
                uniforms ~= basic_lighting_uniforms;
            
            if (config.advanced_lighting)
                uniforms ~= advanced_lighting_uniforms;
            
            try {
                program = new GLProgram(vscode, fscode, uniforms);
            } catch (GLException e) {
                writeln(e.ext_msg);
                throw e;
            }
            
        } catch (StdioException e) {
            writeln(e.msg);
            return false;
        }
        
        calculate_perspective_matrix();
        
        glViewport(0, 0, Engine.width, Engine.height);
        glEnable(GL_DEPTH_TEST);
        glDepthMask(GL_TRUE);
		glDepthFunc(GL_LEQUAL);
		glDepthRange(0.0f, 1.0f);
		glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);
		glFrontFace(GL_CW);
		glBlendFunc(GL_ONE, GL_ONE);
        
        return true;
    }
    
    private static void calculate_perspective_matrix() {
        perspectiveMatrix = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        perspectiveMatrix[0] = frustum_scale / ((cast(float)Engine.width / cast(float)Engine.height));
        perspectiveMatrix[5] = frustum_scale;
        perspectiveMatrix[10] = (z_far + z_near) / (z_near - z_far);
        perspectiveMatrix[14] = (2.0 * z_far * z_near) / (z_near - z_far);
        perspectiveMatrix[11] = -1.0;
    }
    
    static void render(WorldObjectGL obj) {
        
        Quaternion final_rotation;
		Quaternion rot = inverse_rotation;
		float[3] lsp;
		mat4 matrix, translationMatrix, rmatrix;
        
        if (config.perspective) {
            matrix = [
                (1-2*rot.y*rot.y-2*rot.z*rot.z) * (obj.translation[0] + global_offset[0]),
                (2*rot.x*rot.y - 2*rot.w*rot.z) * (obj.translation[1] + global_offset[1]),
                (2*rot.x*rot.z + 2*rot.w*rot.y) * (obj.translation[2] + global_offset[2]),
                0,
                
                (2*rot.x*rot.y + 2*rot.w*rot.z) * (obj.translation[0] + global_offset[0]),
                (1 - 2*rot.x*rot.x - 2*rot.z*rot.z) * (obj.translation[1] + global_offset[1]),
                (2*rot.y*rot.z - 2*rot.w*rot.x) * (obj.translation[2] + global_offset[2]),
                0,
                    
                (2*rot.x*rot.z - 2*rot.w*rot.y) * (obj.translation[0] + global_offset[0]),
                (2*rot.y*rot.z + 2*rot.w*rot.x) * (obj.translation[1] + global_offset[1]),
                (1-2*rot.x*rot.x - 2*rot.y*rot.y) * (obj.translation[2] + global_offset[2]),
                0,
                    
                0, 0, 0, 1
            ];
            
            final_rotation = inverse_rotation * obj.rotation;
            final_rotation.normalize();
            
            translationMatrix = [
                    1, 0, 0, (matrix[0] + matrix[1] + matrix[2]),
                    0, 1, 0, (matrix[4] + matrix[5] + matrix[6]),
                    0, 0, 1, (matrix[8] + matrix[9] + matrix[10]),
                    0, 0, 0, 1
                ];
                
            glUniformMatrix4fv(program.uniforms["perspectiveMatrix"], 1, GL_FALSE, perspectiveMatrix.ptr);
            rmatrix = final_rotation.rotation_matrix();
            glUniformMatrix4fv(program.uniforms["rotationMatrix"], 1, GL_FALSE, rmatrix.ptr);
            glUniformMatrix4fv(program.uniforms["translationMatrix"], 1, GL_FALSE, translationMatrix.ptr);
            //mat4 rawrmatrix = obj.rotation.rotation_matrix();
            //glUniformMatrix4fv(program.uniforms["rawRotationMatrix"], 1, GL_FALSE, rawrmatrix.ptr);
            
            //mat4 rawtransmatrix = [
            //    1, 0, 0, obj.translation[0],
            //    0, 1, 0, obj.translation[1],
            //    0, 0, 1, obj.translation[2],
            //    0, 0, 0, 1
            //];
            
            //glUniformMatrix4fv(program.uniforms["rawTranslationMatrix"], 1, GL_FALSE, rawtransmatrix.ptr);
            
        }
        if (config.advanced_lighting) {
            glUniform4fv(program.uniforms["specularColor"], 1, obj.specular_color.ptr);
            glUniform1f(program.uniforms["roughnessValue"], obj.roughness);
            glUniform1f(program.uniforms["refIndex"], obj.refraction_index);
        }
        if (config.basic_lighting) {
            foreach (light; lights) {
                if (!light.enabled) continue;		
                matrix = [
                    (1-2*rot.y*rot.y-2*rot.z*rot.z) * (light.position[0] + global_offset[0]),
                    (2*rot.x*rot.y - 2*rot.w*rot.z) * (light.position[1] + global_offset[1]),
                    (2*rot.x*rot.z + 2*rot.w*rot.y) * (light.position[2] + global_offset[2]),
                    0,
                    
                    (2*rot.x*rot.y + 2*rot.w*rot.z) * (light.position[0] + global_offset[0]),
                    (1 - 2*rot.x*rot.x - 2*rot.z*rot.z) * (light.position[1] + global_offset[1]),
                    (2*rot.y*rot.z - 2*rot.w*rot.x) * (light.position[2] + global_offset[2]),
                    0,
                        
                    (2*rot.x*rot.z - 2*rot.w*rot.y) * (light.position[0] + global_offset[0]),
                    (2*rot.y*rot.z + 2*rot.w*rot.x) * (light.position[1] + global_offset[1]),
                    (1-2*rot.x*rot.x - 2*rot.y*rot.y) * (light.position[2] + global_offset[2]),
                    0,
                        
                    0, 0, 0, 1
                ];
                
                lsp = [
                    (matrix[0] + matrix[1] + matrix[2]),// + obj.translation[0],
                    (matrix[4] + matrix[5] + matrix[6]),// + obj.translation[1],
                    (matrix[8] + matrix[9] + matrix[10]),// + obj.translation[2]
                ];


                glUniform3fv(program.uniforms["lightPos"], 1, lsp.ptr);
                glUniform3fv(program.uniforms["lightColor"], 1, light.color.ptr);
                //glUniform1i(program.uniforms["lightType"], light.type);
                //glUniform3fv(program.uniforms["lightFaceDir"], 1, light.direction.ptr);

                if (config.advanced_lighting) 
                    glUniform1f(program.uniforms["lightAttenuation"], light.attenuation);
                
                obj.rdata.render();
                glEnable(GL_BLEND);
            }
            glDisable(GL_BLEND);
        } else {
            obj.rdata.render();
        }
    }
    
    static void clear() {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
    
    static ulong create_light(float[3] position, float[3] color, float attenuation, bool enabled) {
        lights ~= Light(position, color, attenuation, enabled);
        return lights.length-1;
    }
        
    static void enable_light(ulong id, bool enabled = true) {
        lights[id].enabled = enabled;
    }
    
    static void destroy_light(ulong id) {
        if (lights.length-id > 1) {
            lights = lights[0..id]~lights[id+1..$];
        } else {
            lights = lights[0..id];
        }
    }
    
    static void replace_light(ulong id, float[3] position, float[3] color, float attenuation, bool enabled) {
        lights[id] = Light(position, color, attenuation, enabled);
    }
    
    static void translate_light(ulong id, float[3] offset) {
        lights[id].position[] += offset[];
    }
    
    static void rotate(float[3] axis, float angle) {
        global_rotation = global_rotation * Quaternion(
			axis[0]*sin(angle/2),
			axis[1]*sin(angle/2),
			axis[2]*sin(angle/2),
			cos(angle/2)
		);
		inverse_rotation = inverse_rotation * Quaternion(
			axis[0]*sin(-angle/2),
			axis[1]*sin(-angle/2),
			axis[2]*sin(-angle/2),
			cos(-angle/2)
		);
    }
    
    static void reset_rotation() {
        global_rotation = (cast(Quaternion)ZeroQuaternion).opposite();
        inverse_rotation = ZeroQuaternion;
    }
    
    static void translate(float[3] offset) {
        global_offset[] += offset[];
    }
    
    //0 == left-right
    //1 == up-down
    //2 == in-out
    static void move(float amount, float[2] xyangle = [0,0]) {
        float[3] euler = global_rotation.euler();
        //up-down:
		//global_offset[1] += amount*cos(euler[2])*sin(euler[0]);
        
        //right-left:
        global_offset[0] += -amount*sin(euler[1]);
		
        
        global_offset[2] += -amount*cos(euler[0])*cos(euler[1]);
    }
}

abstract class WorldObjectGL : WorldObject {
    RenderData rdata;
    float[3] translation = [0,0,0];
    Quaternion rotation = ZeroQuaternion;
    float roughness = 1;
    float refraction_index = 1;
    float[4] specular_color = [1,1,1,1];
    
    override void render() {
        Renderer.render(this);
    }
    
    void set_translation(float[3] offset) {
		translation = offset;
	}
    
	void translate(float[3] offset) {
		translation = [translation[0] + offset[0], translation[1] + offset[1], translation[2] + offset[2]];
	}
    
    void set_rotation(float[3] axis, float angle) {
        rotation = Quaternion(axis[0] * sin(angle/2), axis[1] * sin(angle/2), axis[2] * sin(angle/2), cos(angle/2));
    }
    
    void rotate(float[3] axis, float angle) {
		rotation = rotation * Quaternion(axis[0] * sin(angle/2), axis[1] * sin(angle/2), axis[2] * sin(angle/2), cos(angle/2));
	}

    void move(float amount) {
        float[3] euler = rotation.euler();

        translation[0] += -amount * sin(euler[1]);
        translation[2] += amount*cos(euler[0])*cos(euler[1]);
    }
}

class GLException : EngineException {
    string ext_msg;
    this(string msg, string ext_msg = null) {
        this.ext_msg = ext_msg;
        super(msg);
    }
}

/*  underlying structures  */

private class GLProgram {
    uint program;
    uint vertexShader, fragmentShader;
    
    uint[string] uniforms;
    
    this(string vsCode, string fsCode, string[] uniform_names) {
        vertexShader = compile_shader(vsCode, GL_VERTEX_SHADER);
        fragmentShader = compile_shader(fsCode, GL_FRAGMENT_SHADER);
        
        program = glCreateProgram();
        glAttachShader(program, vertexShader);
        glAttachShader(program, fragmentShader);
        
        glLinkProgram(program);
        
        int linked;
		
		glGetProgramiv(program, GL_LINK_STATUS, &linked);
		if (linked == GL_FALSE) {
			int maxlength;
			glGetProgramiv(program, GL_INFO_LOG_LENGTH, &maxlength);
			char[] programInfoLog = new char[](maxlength);
			glGetProgramInfoLog(program, maxlength, &maxlength, programInfoLog.ptr);
			throw new GLException("Error linking program", text(programInfoLog));
		}
        
        foreach (name; uniform_names) {
            uniforms[name] = glGetUniformLocation(program, name.ptr);
            if (uniforms[name] == -1) {
                throw new GLException("No match for uniform", name);
            }
        }
        
        use();
    }
    
    uint compile_shader(string src, uint type) {
        uint shader = glCreateShader(type);
        
        const(int*) czero;
        
        const(char*)[1] code = [src.ptr];
        
        glShaderSource(shader, 1, code.ptr, czero);
        
        int compiled;
        
        glCompileShader(shader);
        
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
        
        if (!compiled) {
            int maxlength;
			glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &maxlength);
			char[] shaderInfoLog = new char[](maxlength);
            glGetShaderInfoLog(shader, maxlength, &maxlength, shaderInfoLog.ptr);
            
            throw new GLException("Error compiling shader", text(shaderInfoLog));
        }
        
        return shader;
    }
    
    void use() {
        glUseProgram(program);
    }
}

enum VA { Float, Vec2, Vec3, Vec4 }

struct VertexTemplate {
	VA[] attributes;
}

private class GLBuffer {
	uint[] buffers;
	bool indexed;
	this(VertexTemplate vt, bool indexed) {
		if (indexed) buffers.length = 2;
		else buffers.length = 1;
		this.indexed = indexed;
		glGenBuffers(cast(uint)buffers.length, buffers.ptr);
		bind();
		uint size, totalsize;
		void* vp;
		foreach (a; vt.attributes) {
			final switch(a) {
				case VA.Float: totalsize += 4; break;
				case VA.Vec2: totalsize += 8; break;
				case VA.Vec3: totalsize += 12; break;
				case VA.Vec4: totalsize += 16; break;
			}
		}
		foreach (uint n,a; vt.attributes) {
			glEnableVertexAttribArray(n);
			final switch(a) {
				case VA.Float:
					glVertexAttribPointer(n, 1, GL_FLOAT, GL_FALSE, totalsize, vp+size);
					size += 4;
				break;
				case VA.Vec2:
					glVertexAttribPointer(n, 2, GL_FLOAT, GL_FALSE, totalsize, vp+size);
					size += 8;
				break;
				case VA.Vec3:
					glVertexAttribPointer(n, 3, GL_FLOAT, GL_FALSE, totalsize, vp+size);
					size += 12;
				break;
				case VA.Vec4:
					glVertexAttribPointer(n, 4, GL_FLOAT, GL_FALSE, totalsize, vp+size);
					size += 16;
				break;
			}
		}
	}
	void bind() {
		glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
		if (indexed) glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
	}
	void buffer_data(T)(float[] vertexData, T[] indexData, uint hint=GL_STATIC_DRAW) if (is(T == ubyte) || is(T == ushort) || is(T == uint)) {
		bind();
		glBufferData(GL_ARRAY_BUFFER, float.sizeof * vertexData.length, vertexData.ptr, hint);
		if (indexed) glBufferData(GL_ELEMENT_ARRAY_BUFFER, T.sizeof * indexData.length, indexData.ptr, hint);
	}
}

enum PrimitiveType { Points = GL_POINTS, Lines = GL_LINES, Triangles = GL_TRIANGLES }

class Mesh {
    ushort[] indexData;
    float[] vertexData;
    float[] normalData;
    
    @property float[6] bounding_box() {
        writeln("snrm");
        float minx=0,maxx=0,miny=0,maxy=0,minz=0,maxz=0;
        for (ulong v=0; v<vertexData.length; v+=3) {
            minx = vertexData[v] < minx ? vertexData[v] : minx;
            maxx = vertexData[v] > maxx ? vertexData[v] : maxx;
            miny = vertexData[v+1] < miny ? vertexData[v+1] : miny;
            maxy = vertexData[v+1] > maxy ? vertexData[v+1] : maxy;
            minz = vertexData[v+2] < minz ? vertexData[v+2] : minz;
            maxz = vertexData[v+2] > maxz ? vertexData[v+2] : maxz;
        }
        writeln("bb = ",[minx,miny,minz,maxx,maxy,maxz]);
        return [minx,miny,minz,maxx,maxy,maxz];
    }
}


interface RenderData {
	void render();
}

class RenderDataIndexed : RenderData {
	GLBuffer buffer;
	uint vertexcount;
	PrimitiveType type;
	uint vao;
	this(T)(T[] vertices, ushort[] indices, PrimitiveType type, VertexTemplate vt = VertexTemplate([VA.Vec3, VA.Vec3, VA.Vec3])) if (is(T == float) || __traits(compiles, cast(float[])(vertices[0]))) {
		this.type = type;
		assert(indices.length < uint.max);
		glGenVertexArrays(1, &vao);
		glBindVertexArray(vao);
		buffer = new GLBuffer(vt, true);
		static if (is(T == float)) {
			buffer.buffer_data(vertices, indices);
		} else {
			float[] vertexData;
			foreach (v; vertices) {
				vertexData ~= cast(float[])v;
			}
			buffer.buffer_data(vertexData, indices);
		}
		vertexcount = cast(uint)indices.length;
	}
	void render() {
		glBindVertexArray(vao);
		buffer.bind();
		glDrawElements(type, vertexcount, GL_UNSIGNED_SHORT, cast(void*)0);
	}
}

class RenderDataUnindexed : RenderData {
	GLBuffer buffer;
	uint vertexcount;
	PrimitiveType type;
	this(T)(T[] vertices, PrimitiveType type, VertexTemplate vt = VertexTemplate([VA.Vec3, VA.Vec3, VA.Vec3])) if (is(T == float) || __traits(compiles, cast(float[])(vertices[0]))) {
		this.type = type;
		assert(vertices.length < uint.max);
		buffer = new GLBuffer(vt, false);
		buffer.bind();
		static if (is(T == float)) {
			buffer.buffer_data!(ushort)(vertices, []);
		} else {
			float[] vertexData;
			foreach (v; vertices) {
				vertexData ~= cast(float[])v;
			}
			buffer.buffer_data!(ushort)(vertexData, []);
		}
		vertexcount = cast(uint)vertices.length;
	}
	void render() {
		buffer.bind();
		glDrawArrays(type, 0, vertexcount);
	}
}

class Vertex {
	float[3] position;
	float[3] color;
	float[3] normal;
	int normalcount;
	T opCast(T)() if (is(T == float[])) {
		return position ~ color ~ normal;
	}
	this(float[3] position, float[3] color, float[3] normal=[0,0,0]) {
		this.position = position;
		this.color = color;
		this.normal = normal;
	}
}

void generate_normals(Vertex[] vertices, ushort[] indices) {
	//writeln("check");
	//foreach (v; vertices) {
	//	writeln(v.normal);
	//}
	float[3] v1, v2, n;
	Vertex vex1, vex2, vex3;
	//f/loat x1, x2, x3, y1, y2, y3, z1, z2, z3;
	for (int i=0; i<indices.length; i+=3) {
		vex1 = vertices[indices[i]];
		vex2 = vertices[indices[i+1]];
		vex3 = vertices[indices[i+2]];
		//writeln("vex1.normal=",vex1.normal);
		v1 = [
				vex1.position[0]-vex2.position[0],
				vex1.position[1]-vex2.position[1],
				vex1.position[2]-vex2.position[2]
			];
		v2 = [
				vex3.position[0]-vex1.position[0],
				vex3.position[1]-vex1.position[1],
				vex3.position[2]-vex1.position[2]
			];
		n = [
				v1[1]*v2[2] - v1[2]*v2[1],
				v1[2]*v2[0] - v1[0]*v2[2],
				v1[0]*v2[1] - v1[1]*v2[0]
			];
		vex1.normal[0] += n[0];
		vex1.normal[1] += n[1];
		vex1.normal[2] += n[2];
		vex2.normal[0] += n[0];
		vex2.normal[1] += n[1];
		vex2.normal[2] += n[2];
		vex3.normal[0] += n[0];
		vex3.normal[1] += n[1];
		vex3.normal[2] += n[2];
		vex1.normalcount++;
		vex2.normalcount++;
		vex3.normalcount++;
		//writeln(vex1.normalcount, vertices[indices[i]].normalcount);
	}
	foreach (ref v; vertices) {
		//writeln(v.normalcount, v.normal);
		v.normal[0] /= v.normalcount;
		v.normal[1] /= v.normalcount;
		v.normal[2] /= v.normalcount;
		//writeln(v.normal);
		auto m = sqrt(v.normal[0]*v.normal[0] + v.normal[1]*v.normal[1] + v.normal[2]*v.normal[2]);
		//writeln(m);
		v.normal[0] /= m;
		v.normal[1] /= m;
		v.normal[2] /= m;
	}
	//foreach (v; vertices) {
	//	writeln(v.normal);
	//}
}
