/**
 * @file
 * @brief     Tensor NIF resource manager.
 * @author    Igor Lesik 2020
 * @copyright Igor Lesik 2020
 *
 */
#pragma once

#include <erl_nif.h>

#include "tensor/tensor.hpp"

namespace numy::tnsr {

/**
 * NIFResource manages Tensor NIF resources. 
 */
class NIFResource
{
public:
    using ResType = ErlNifResourceType*;

private:
    ResType res_type_ = nullptr;

public:
    ERL_NIF_TERM ok_atom_, true_atom_, false_atom_;

public:
    /**
     * Notice that enif_open_resource_type is only allowed to be called
     * in the two callbacks `load` and `upgrade`.
     */
    ResType open(ErlNifEnv* env)
    {
        ok_atom_ = enif_make_atom(env, "ok");
        true_atom_ = enif_make_atom(env, "true");
        false_atom_ = enif_make_atom(env, "false");


        res_type_ = enif_open_resource_type(
            env,
            "Elixir.Numy.Tensor",
            "resource type Tensor",
            this->dtor,
            (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER),
            nullptr //ErlNifResourceFlags* tried
        );

        return res_type_;
    }

    static
    void dtor(ErlNifEnv* env, void* obj)
    {
        numy::Tensor* tensor = (numy::Tensor*) obj;
        //assert(tensor->magic == numy::Tensor::MAGIC);
        if (tensor->magic != numy::Tensor::MAGIC) {
            enif_raise_exception(env,
                enif_make_string(env, "Tensor bad magic", ERL_NIF_LATIN1));
        }
        else {
            if (tensor->data != nullptr) {
                enif_free(tensor->data);
            }
        }
    }

    numy::Tensor* allocate() {
        return static_cast<numy::Tensor*>(
            enif_alloc_resource(res_type_, sizeof(numy::Tensor)));
    }

    numy::Tensor* get(ErlNifEnv* env, const ERL_NIF_TERM tensorNifTerm) {
        numy::Tensor* tensor{nullptr};
        return (enif_get_resource(env, tensorNifTerm, res_type_, (void**) &tensor))?
            tensor:
            nullptr;
    }
};

static inline
numy::Tensor* getTensor(ErlNifEnv* env, const ERL_NIF_TERM nifTensor) {
    NIFResource* resourceMngr = (NIFResource*) enif_priv_data(env);
    return resourceMngr->get(env, nifTensor);
}

static inline ERL_NIF_TERM getOkAtom(ErlNifEnv* env) {
    return ((NIFResource*) enif_priv_data(env))->ok_atom_;
}

static inline ERL_NIF_TERM getTrueAtom(ErlNifEnv* env) {
    return ((NIFResource*) enif_priv_data(env))->true_atom_;
}

static inline ERL_NIF_TERM getFalseAtom(ErlNifEnv* env) {
    return ((NIFResource*) enif_priv_data(env))->false_atom_;
}

static inline ERL_NIF_TERM getBoolAtom(ErlNifEnv* env, bool truth) {
    return truth ? getTrueAtom(env) : getFalseAtom(env);
}

} // namespace numy::tnsr
