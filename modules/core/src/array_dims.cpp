/**
 *  @file   array_dims.cpp
 *  @brief Representation for NDArray's dimensions. Inspired from Tensorflow
 *  @ingroup core
 *
 *  @author Christophe Ecabert
 *  @date   14.02.18
 *  Copyright © 2018 Christophe Ecabert. All rights reserved.
 */

#include <utility>

// Protobuff
#include "array_dims.pb.h"

#include "facekit/core/array_dims.hpp"


/**
 *  @namespace  FaceKit
 *  @brief      Development space
 */
namespace FaceKit {
  
#pragma mark -
#pragma mark Initialization
  
/*
 *  @name   ArrayDims
 *  @fn     ArrayDims(void)
 *  @brief  Constructor
 */
ArrayDims::ArrayDims(void) : dims_(kMaxDim + 1, 0), n_elem_(1) {}
  
/*
 *  @name   ArrayDims
 *  @fn     explicit ArrayDims(const ArrayDimsProto& proto)
 *  @brief  Constructor from protobuf object
 */
ArrayDims::ArrayDims(const ArrayDimsProto& proto) : ArrayDims() {
  this->FromProto(proto);
}
  
/*
 *  @name   ArrayDims
 *  @fn     explicit ArrayDims(const std::initializer_list<size_t>& dims)
 *  @brief  Constructor
 *  @param[in] dims List of dimensions
 */
ArrayDims::ArrayDims(const std::initializer_list<size_t>& dims) : ArrayDims() {
  auto it = dims.begin();
  size_t i = 0;
  for (; it != dims.end() && i < kMaxDim; ++it, ++i) {
    dims_[i] = *it;
  }
  dims_[kMaxDim] = i;
  this->ComputeNElement();
}
  
// Static instance
constexpr size_t ArrayDims::kMaxDim;
  
#pragma mark -
#pragma mark Usage
  
/*
 *  @name   IsValid
 *  @fn     static bool IsValid(const ArrayDimsProto& proto)
 *  @brief  Check if a given protobuf message is valid
 *  @param[in]  proto Message to check
 *  @return true if valid, false otherwise
 */
bool ArrayDims::IsValid(const ArrayDimsProto& proto) {
  return proto.dims_size() < kMaxDim;
}
  
/*
 *  @name   ToProto
 *  @fn     void ToProto(ArrayDimsProto* proto) const
 *  @brief  Export to a corresponding Protobuf object
 *  @param[out] proto Protobuf message object
 */
void ArrayDims::ToProto(ArrayDimsProto* proto) const {
  proto->Clear();
  for (size_t i = 0; i < dims_[kMaxDim]; ++i) {
    proto->add_dims()->set_size(dims_[i]);
  }
}
  
/*
 *  @name   FromProto
 *  @fn     int FromProto(const ArrayDimsProto& proto)
 *  @brief  Initialize from protobuf message
 *  @param[in] proto  Message from which to initialize
 *  @return -1 if message is not valid, 0 otherwise
 */
int ArrayDims::FromProto(const ArrayDimsProto& proto) {
  if (IsValid(proto)) {
    for(int i = 0; i < proto.dims_size(); ++i) {
      this->AddDim(proto.dims(i).size());
    }
    return 0;
  }
  return -1;
}
  
/*
 *  @name   AddDim
 *  @fn void AddDim(const size_t& dim)
 *  @brief  Add dimension at the end
 */
void ArrayDims::AddDim(const size_t& dim) {
  size_t& d = dims_[kMaxDim];
  if(d < kMaxDim) {
    // There is some space left
    dims_[d] = dim;
    d += 1;
    // Update n_elem_
    this->ComputeNElement();
  }
}
  
/*
 *  @name   RemoveDim
 *  @fn     void RemoveDim(const size_t& axis)
 *  @brief  Remove dimension along a given `axis`
 *  @param[in]  axis  Dimension to remove
 */
void ArrayDims::RemoveDim(const size_t& axis) {
  if (axis < kMaxDim) {
    std::vector<size_t> dim(kMaxDim + 1, 0);
    auto it = dim.begin();
    // Copy only dimensions not being remove
    const size_t& d = dims_[kMaxDim];
    for (size_t i = 0; i < d; ++i) {
      if (i != axis) {
        *it = dims_[i];
        ++it;
      }
    }
    // Update dimensions
    dim[kMaxDim] = dims_[kMaxDim] - 1;
    std::move(dim.begin(), dim.end(), dims_.begin());
    this->ComputeNElement();
  }
}
  
/*
 *  @name   Clear
 *  @fn     void Clear(void)
 *  @brief  Clear dimensions stored
 */
void ArrayDims::Clear(void) {
  dims_.assign(kMaxDim + 1, 0);
  n_elem_ = 1;
}
  
#pragma mark -
#pragma mark Accessors
  
/*
 *  @name   set_dim
 *  @fn     void set_dim(const size_t& axis, const size_t& dim)
 *  @brief  Set dimension for a given axis
 *  @param[in] axis Axis on which to set dimensions
 *  @param[in] dim  Dimension
 */
void ArrayDims::set_dim(const size_t& axis, const size_t& dim) {
  if (axis < dims_[kMaxDim]) {
    dims_[axis] = dim;
    this->ComputeNElement();
  }
}
  
#pragma mark -
#pragma mark Private
  
/*
 *  @name   ComputeNElement
 *  @fn     void ComputeNElement(void)
 *  @brief  Establish how many element are store in the array
 */
void ArrayDims::ComputeNElement(void) {
  // TODO: If dimensions are too large this might overflow
  size_t n = 1;   //Rank 0 -> scalar -> 1 elements
  for (size_t i = 0; i < dims_[kMaxDim]; ++i) {
    n *= dims_[i];
  }
  n_elem_ = n;
}
  
}  // namespace FaceKit
