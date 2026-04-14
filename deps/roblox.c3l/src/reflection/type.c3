module roblox::reflection::type;

import logger;
import roblox;
import nt_ext;
import msvc_ext;

faultdef UNHANDLED_TYPE;

alias Instances = Vector{Instance};
alias InstancesEx = VectorEx{Instance};

alias Tuple = Vector{Variant};
alias ValueArray = Tuple; // has the same memory layout as Tuple
alias TupleEx = VectorEx{Variant};
alias ValueArrayEx = TupleEx;

enum TTypeId { VOID, BOOL, INT, INT64, FLOAT, DOUBLE, STRING, PROTECTED_STRING, INSTANCE, INSTANCES, RAY, VECTOR2, VECTOR3, VECTOR2INT16, VECTOR3INT16, RECT2D, COORDINATE_FRAME, COLOR3, COLOR3UINT8, UDIM, UDIM2, FACES, AXES, REGION3, REGION3INT16, CELL_ID, GUID_DATA, PHYSICAL_PROPERTIES, BRICK_COLOR, SYSTEM_ADDRESS, BINARY_STRING, SURFACE, COLLECTION_HANDLE, ENUM, PROPERTY, TUPLE, VALUE_ARRAY, VALUE_TABLE, VALUE_MAP, VARIANT, GENERIC_FUNCTION, WEAK_FUNCTION_REF, COLOR_SEQUENCE, COLOR_SEQUENCE_KEYPOINT, NUMBER_RANGE, NUMBER_SEQUENCE, NUMBER_SEQUENCE_KEYPOINT, INPUT_OBJECT, CONNECTION, CONTENT_ID, DESCRIBED_BASE, REF_TYPE, QFONT, QDIR, EVENT_INSTANCE, TWEEN_INFO, DOCK_WIDGET_PLUGIN_GUI_INFO, PLUGIN_DRAG, RANDOM, PATH_WAYPOINT, FLOAT_CURVE_KEY, ROTATION_CURVE_KEY, VALUE_CURVE_KEY, SHARED_STRING, DATE_TIME, RAYCAST_PARAMS, RAYCAST_RESULT, OVERLAP_PARAMS, LAZY_TABLE, DEBUG_TABLE, CATALOG_SEARCH_PARAMS, OPTIONAL_COORDINATE_FRAME, CSGPROPERTY_DATA, UNIQUE_ID, FONT, SHARED_TABLE, SHARED_TABLE_ITERATOR, ANIMATION_MASK, ANIMATION_POSE, CLIP_EVALUATOR, OPEN_CLOUD_MODEL, REMOTE_INSTANCE, SECURITY_CAPABILITIES, ARTICULATED_JOINT, ANIMATION_CONTEXT, SECRET, BUFFER, PATH2DCONTROL_POINT, REPLICATION_PV, FACS_REPLICATION_DATA, ANIMATION_MASK_MODIFIER, CONTENT, NET_ASSET_HANDLE, NET_ASSET_REF, OBJECT, AD_REWARD, ASSET_CONTENT_MAP, SLIM_REPLICATION_DATA, USER, MAX }

struct Type {
    void* vftable;
    CppString* tag;
    char[32] pad0;
    TTypeId id;
}

struct Variant {
    Type* type;

    struct value {
        void* vftable;
        union {
            char[64] data;
            uptr address;
            bool b;
            int i;
            long l;
            float f;
            double d;
            CppString s;
            RbxRay r;
            Vector2 v2;
            Vector3 v3;
            Vector2int16 v2i;
            Vector3int16 v3i;
            Rect2D r2d;
        }
    }
}

typedef VariantEx = inline WrapperEx{Variant};

fn String? VariantEx.to_string(&self, Allocator allocator, TTypeId* id_ptr = null) {
    Type type_info = self.memory.read_type(Type, (uptr)self.type)!;
    VariantFormatterFn formatter = formatter::handlers[type_info.id];

    if (id_ptr) *id_ptr = type_info.id;

    return formatter(allocator, self, &type_info);
}

fn String TupleEx.to_string(&self, Allocator allocator) {
    DString result = dstring::new(allocator);
    defer result.free();

    result.append_string("{ ");

    bool first = true;
    foreach (&variant : self) {
        VariantEx ex;

        if (catch ex.init(self.memory, self.get_address(variant))) continue;
        if (!first) result.append_string(", ");

        first = false;

        TTypeId id;
        String format = ex.to_string(allocator, &id) ?? ("nil --[[error]]").copy(allocator);

        result.append_string(format);
        format.free(allocator);
    }

    result.append_string(" }");
    return result.copy_str(allocator);
}
