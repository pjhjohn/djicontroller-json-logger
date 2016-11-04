# roto.rb - simple Ruby rotation module v1.0
#           2D/3D rotation of arbitrary point in the space.
#           version 1.0 released on December 21, 2014
#           Additional information about quaternions see:

'''
  The MIT License (MIT)
  Copyright (c) 2014 Jaime Ortiz
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
'''

module Roto
  def Roto.info()
    return "rotor - rotates a given point around an arbitrary defined axis"
  end
  
  # Vector and Quaternion algebra

  def Roto.vectorCrossProduct( u, v )
    """Returns the vector resulting from the cross product between two vectors"""
    return [ u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0] ] 
  end
  
  def Roto.vectorDotProduct( u, v )
    """Returns the scalar quantity representing the dot product of two vectors"""
    return u[0] * v[0] + u[1] * v[1] + u[2] * v[2]
  end
    
  def Roto.vectorSum( u, v )
    """Returns the sum of two vectors"""
    return [ u[0] + v[0], u[1] + v[1], u[2] + v[2] ]
  end

  def Roto.vectorScaling( scale, v )
    """Returns the multiplication of a vector and a scalar"""
    return [ scale * v[0], scale * v[1], scale * v[2] ]
  end
    
  def Roto.vectorMagnitude( v )
    """Returns the magnitude of the vector"""
    return ( ( v[0] ** 2 + v[1] ** 2 + v[2] ** 2 ) ** 0.5 )
  end
    
  def Roto.vectorNormalized( v )
    """Returns de normalized vector"""
    v_mag = Roto.vectorMagnitude( v );
    return [ v[0] / v_mag, v[1] / v_mag, v[2] / v_mag ] 
  end
    
  def Roto.angleBetween2VectorsRad( u, v )
    u_mag = Roto.vectorMagnitude( u )
    v_mag = Roto.vectorMagnitude( v )
    udotv = Roto.vectorDotProduct( u, v )
    return Math.acos( udotv / ( u_mag * v_mag ) )
  end
    
  def Roto.angleBetween2VectorsDeg( u, v )
    return Roto.rad2deg( Roto.angleBetween2VectorsRad( u, v ) )  
  end
    
  def Roto.quaternionDotProduct( q0, q1 )
    """Returns the scalar quantiry representing the dot product of two vectors"""
    return q0[0] * q1[0] + q0[1] * q1[1] + q0[2] * q1[2] + q0[3] * q1[3]
  end
    
  def Roto.quaternionProduct( q0, q1 )
    s0 = q0[0]
    s1 = q1[0]
    v0 = [ q0[1], q0[2], q0[3] ]
    v1 = [ q1[1], q1[2], q1[3] ]
    real_part = s0 * s1 - Roto.vectorDotProduct( v0, v1 )
    vector_scaling_1 = Roto.vectorScaling( s0, v1 )
    vector_scaling_2 = Roto.vectorScaling( s1, v0 )
    vector_cross_product_1 = Roto.vectorCrossProduct( v0, v1 )
    vector_sum_1 = Roto.vectorSum( vector_scaling_1, vector_scaling_2 )
    vector_sum_2 = Roto.vectorSum( vector_sum_1, vector_cross_product_1 )
    return[ real_part, vector_sum_2[0], vector_sum_2[1], vector_sum_2[2] ] 
  end
    
  def Roto.quaternionMagnitude( q )
    """Returns the magnitude of a quaternion"""
    return ( ( q[0] ** 2 + q[1] ** 2 + q[2] ** 2 + q[3] ** 2 ) ** 0.5 )
  end
    
  def Roto.quaternionInverse( q )
    """Returns the inverse of a quaternion"""
    return ( [ q[0], -q[1], -q[2], -q[3] ] )
  end
    
  def Roto.quaternionRotor( v, phi )
    """Returns the quaternion representing the rotation around the vector v by an angle phi expressed in radians"""
    return [ Math.cos( phi / 2.0 ), 
         Math.sin( phi / 2.0 ) * v[0], 
         Math.sin( phi / 2.0 ) * v[1], 
         Math.sin( phi / 2.0 ) * v[2] ]
  end
         
  def Roto.deg2rad( angle_deg )
    """Converts the given angle in degrees to radians"""
    return angle_deg * Math::PI / 180.0
  end
  
  def Roto.rad2deg( angle_rad )
    """Converts the given angle in radians to degrees"""
    return angle_rad * 180.0 / Math::PI
  end
  
  def Roto.quaternionToMatrix( q )
    """Converts the quaternion q to a 4 x 4 matrix"""
    matrix4x4 = [ ]
    nq = Roto.quaternionMagnitude( q )
    s =  nq > 0.0 ? ( 2.0 / nq ) : 0.0
    xs = q[ 1 ] * s
    ys = q[ 2 ] * s
    zs = q[ 3 ] * s
    wx = q[ 0 ] * xs
    wy = q[ 0 ] * ys
    wz = q[ 0 ] * zs
    xx = q[ 1 ] * xs
    xy = q[ 1 ] * ys
    xz = q[ 1 ] * zs
    yy = q[ 2 ] * ys
    yz = q[ 2 ] * zs
    zz = q[ 3 ] * zs
    matrix4x4[ 0 ] = 1.0 - ( yy + zz )
    matrix4x4[ 1 ] = xy - wz
    matrix4x4[ 2 ] = xz + wy
    matrix4x4[ 3 ] = 0.0
    matrix4x4[ 4 ] = xy + wz
    matrix4x4[ 5 ] = 1.0 - ( xx + zz )
    matrix4x4[ 6 ] = yz - wx
    matrix4x4[ 7 ] = 0.0
    matrix4x4[ 8 ] = xz - wy
    matrix4x4[ 9 ] = yz + wx
    matrix4x4[ 10 ] = 1.0 - ( xx + yy )
    matrix4x4[ 11 ] = 0.0
    matrix4x4[ 12 ] = 0.0
    matrix4x4[ 13 ] = 0.0
    matrix4x4[ 14 ] = 0.0
    matrix4x4[ 15 ] = 1.0
    return matrix4x4
  end
  
  def Roto.matrix4x4_Multiplication( a, b )
    # a = this rotation
    # b = last rotation
    matrix4x4 = [ ]
    matrix4x4[ 0 ] = a[ 0 ] * b[ 0 ] + a[ 1 ] * b[ 4 ] + a[ 2 ] * b[ 8 ] + a[ 3 ] * b[ 12 ]
    matrix4x4[ 1 ] = a[ 0 ] * b[ 1 ] + a[ 1 ] * b[ 5 ] + a[ 2 ] * b[ 9 ] + a[ 3 ] * b[ 13 ]
    matrix4x4[ 2 ] = a[ 0 ] * b[ 2 ] + a[ 1 ] * b[ 6 ] + a[ 2 ] * b[ 10 ] + a[ 3 ] * b[ 14 ]
    matrix4x4[ 3 ] = a[ 0 ] * b[ 3 ] + a[ 1 ] * b[ 7 ] + a[ 2 ] * b[ 11 ] + a[ 3 ] * b[ 15 ]
    matrix4x4[ 4 ] = a[ 4 ] * b[ 0 ] + a[ 5 ] * b[ 4 ] + a[ 6 ] * b[ 8 ] + a[ 7 ] * b[ 12 ]
    matrix4x4[ 5 ] = a[ 4 ] * b[ 1 ] + a[ 5 ] * b[ 5 ] + a[ 6 ] * b[ 9 ] + a[ 7 ] * b[ 13 ]
    matrix4x4[ 6 ] = a[ 4 ] * b[ 2 ] + a[ 5 ] * b[ 6 ] + a[ 6 ] * b[ 10 ] + a[ 7 ] * b[ 14 ]
    matrix4x4[ 7 ] = a[ 4 ] * b[ 3 ] + a[ 5 ] * b[ 7 ] + a[ 6 ] * b[ 11 ] + a[ 7 ] * b[ 15 ]
    matrix4x4[ 8 ] = a[ 8 ] * b[ 0 ] + a[ 9 ] * b[ 4 ] + a[ 10 ] * b[ 8 ] + a[ 11 ] * b[ 12 ]
    matrix4x4[ 9 ] = a[ 8 ] * b[ 1 ] + a[ 9 ] * b[ 5 ] + a[ 10 ] * b[ 9 ] + a[ 11 ] * b[ 13 ]
    matrix4x4[ 10 ] = a[ 8 ] * b[ 2 ] + a[ 9 ] * b[ 6 ] + a[ 10 ] * b[ 10 ] + a[ 11 ] * b[ 14 ]
    matrix4x4[ 11 ] = a[ 8 ] * b[ 3 ] + a[ 9 ] * b[ 7 ] + a[ 10 ] * b[ 11 ] + a[ 11 ] * b[ 15 ]
    matrix4x4[ 12 ] = a[ 12 ] * b[ 0 ] + a[ 13 ] * b[ 4 ] + a[ 14 ] * b[ 8 ] + a[ 15 ] * b[ 12 ]
    matrix4x4[ 13 ] = a[ 12 ] * b[ 1 ] + a[ 13 ] * b[ 5 ] + a[ 14 ] * b[ 9 ] + a[ 15 ] * b[ 13 ]
    matrix4x4[ 14 ] = a[ 12 ] * b[ 2 ] + a[ 13 ] * b[ 6 ] + a[ 14 ] * b[ 10 ] + a[ 15 ] * b[ 14 ]
    matrix4x4[ 15 ] = a[ 12 ] * b[ 3 ] + a[ 13 ] * b[ 7 ] + a[ 14 ] * b[ 11 ] + a[ 15 ] * b[ 15 ]
    return matrix4x4
  end
  
  #  === Rotation functions ===
    
  def Roto.rotate( p0, angle, v )
    """Rotates an arbitrary point p0 around an arbitrary axis v by an angle expessed in degrees"""
    v         = Roto.vectorNormalized( v )
    p         = [ 0, p0[0], p0[1], p0[2] ]
    angle_rad = Roto.deg2rad( angle )
    q         = Roto.quaternionRotor( v, angle_rad )
    invq      = Roto.quaternionInverse( q )
    qp        = Roto.quaternionProduct( q, p )
    qpinvq    = Roto.quaternionProduct( qp, invq )
    return [ qpinvq[ 1 ], qpinvq[ 2 ], qpinvq[ 3 ] ]
  end
    
  def Roto.rotateX( p0, angle )
    """Rotates an arbitrary point p0 around the X axis by an angle expressed in degrees"""
    q1 = Roto.rotate( p0, angle, [ 1, 0, 0 ] )
    return [ q1[ 0 ], q1[ 1 ], q1[ 2 ] ]
  end
    
  def Roto.rotateY( p0, angle )
    """Rotates an arbitrary point p0 around the Y axis by an angle expressed in degrees"""
    q1 = Roto.rotate( p0, angle, [ 0, 1, 0 ] )
    return [ q1[ 0 ], q1[ 1 ], q1[ 2 ] ]
  end
    
  def Roto.rotateZ( p0, angle )
    """Rotates an arbitrary point p0 around the Z axis by an angle expressed in degrees"""
    q1 = Roto.rotate( p0, angle, [ 0, 0, 1 ] )
    return [ q1[ 0 ], q1[ 1 ], q1[ 2 ] ]
  end  
end