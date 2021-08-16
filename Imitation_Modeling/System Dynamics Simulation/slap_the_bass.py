"""
Python model "bass.py"
Translated using PySD version 0.10.0
"""
from __future__ import division
import numpy as np
from pysd import utils
import xarray as xr

from pysd.py_backend.functions import cache
from pysd.py_backend import functions

_subscript_dict = {}

_namespace = {
    'TIME': 'time',
    'Time': 'time',
    'Potential Adopters':'potential_adopters',
    'Adopters1':'adopters_1',
    'Adopters2':'adopters_2',
    'Adoption rate 1':'adoption_rate_1',
    'Adoption rate 2':'adoption_rate_2',
    'Reverse rate 1':'reverse_rate_1',
    'Reverse rate 2':'reverse_rate_2', 
    'Competitive rate 1':'competitive_rate_1',
    'Competitive rate 2':'competitive_rate_2', 
    'Tolerance rate 1':'tolerance_rate_1', 
    'Tolerance rate 2':'tolerance_rate_2', 
    'Market rate 1':'market_rate_1', #K1
    'Market rate 2':'market_rate_2', #K2
    'womEffectness1':'wom_effectness_1',
    'womEffectness2':'wom_effectness_2',
    'AdEffectness1':'ad_effectness_1',
    'AdEffectness2':'ad_effectness_2',
    'contact rate 1':'contact_rate_1',
    'contact rate 2':'contact_rate_2',
    'Neutral rate 1':'neutral_rate_1', #P13
    'Neutral rate 2':'neutral_rate_2', #P23
    'Chaotic rate 1':'chaotic_rate_1', #P11
    'Chaotic rate 2':'chaotic_rate_2', #P21
    'total population':'total_population',
    'adoption from WOM 1':'adoption_from_wom_1',
    'adoption from WOM 2':'adoption_from_wom_2',
    'adoption from AD 1':'afoption_from_ad_1',
    'adoption from AD 2':'afoption_from_ad_2',
    'FINAL TIME': 'final_time',
    'INITIAL TIME': 'initial_time',
    'SAVEPER': 'saveper',
    'TIME STEP': 'time_step'
}


__pysd_version__ = "0.10.0"

__data = {'scope': None, 'time': lambda: 0}


def _init_outer_references(data):
    for key in data:
        __data[key] = data[key]


def time():
    return __data['time']()


@cache('step')
def potential_adopters():
    """
    Real Name: b'Potential Adopters'
    Original Eqn: b'INTEG(-adoption rate, total population)'
    Units: b'person'
    Limits: (None, None)
    Type: component

    b''
    """
    return _integ_potential_adopters()


@cache('step')
def adopters_1():
    """
    Real Name: b'Adopters1'
    Original Eqn: b'INTEG(adoption rate 1, 0)'
    Units: b'person'
    Limits: (0, total population)
    Type: component

    b''
    """
    return _integ_adopters1()

@cache('step')
def adopters_2():
    """
    Real Name: b'Adopters2'
    Original Eqn: b'INTEG(adoption rate 2, 0)'
    Units: b'person'
    Limits: (0, total population)
    Type: component

    b''
    """
    return _integ_adopters2()

@cache('step')
def adoption_rate_1():
    """
    Real Name: b'adoption rate 1'
    Original Eqn: b'adoption from AD 1 + adoption from WOM 1'
    Units: b'person/Month'
    Limits: (None, None)
    Type: component

    b''
    """
    return adoption_from_ad_1()+adoption_from_wom_1()

@cache('step')
def adoption_rate_2():
    """
    Real Name: b'adoption rate 2'
    Original Eqn: b'adoption from AD 2 + adoption from WOM 2'
    Units: b'person/Month'
    Limits: (None, None)
    Type: component

    b''
    """
    return adoption_from_ad_2()+adoption_from_wom_2()

@cache('step')
def reverse_rate_1():
    """
    Real Name: b'reverse rate 1'
    Original Eqn: b'Adopters_1 * P13 * K1'
    Units: b'person/Month'
    Limits: (None, None)
    Type: component

    b''
    """
    return adopters_1() * neutral_rate_1() * market_rate_1()

@cache('step')
def reverse_rate_2():
    """
    Real Name: b'reverse rate 2'
    Original Eqn: b'Adopters_2 * P23 * K2'
    Units: b'person/Month'
    Limits: (None, None)
    Type: component

    b''
    """
    return adopters_2() * neutral_rate_2() * market_rate_2()

@cache('step')
def competitive_rate_1():
    """
    Real Name: b'competitive rate 1'
    Original Eqn: b'tolerance_rate_1 * wom_effectness_2 * contact_rate_2 * adopters_1 * (1-P11-P13*K1) * adopters_2 * P21 / total_population()'
    Units: b'person/Month'
    Limits: (None, None)
    Type: component

    b''
    """
    return  tolerance_rate_1() * wom_effectness_2() * contact_rate_2() * adopters_1() * (1-chaotic_rate_1()-neutral_rate_1()*market_rate_1()) * adopters_2() * chaotic_rate_2() / total_population()

@cache('step')
def competitive_rate_2():
    """
    Real Name: b'competitive rate 2'
    Original Eqn: b'tolerance_rate_2 * wom_effectness_1 * contact_rate_1 * adopters_2 * (1-P21-P23*K2) * adopters_1 * P11 / total_population()'
    Units: b'person/Month'
    Limits: (None, None)
    Type: component

    b''
    """
    return tolerance_rate_2() * wom_effectness_1() * contact_rate_1() * adopters_2() * (1-chaotic_rate_2()-neutral_rate_2()*market_rate_2()) * adopters_1() * chaotic_rate_1() / total_population()


@cache('step')
def tolerance_rate_1():
    """
    Real Name: b'tolerance rate 1'
    Original Eqn: b'(wom_effectness_1+wom_effectness_2)/(ad_effectness_1+ad_effectness_2+wom_effectness_1+wom_effectness_2)'
    Units: b'person/contact'
    Limits: (None, None)
    Type: component

    b''
    """
    return (wom_effectness_1()+wom_effectness_2())/(ad_effectness_1()+ad_effectness_2()+wom_effectness_1()+wom_effectness_2())

@cache('step')
def tolerance_rate_2():
    """
    Real Name: b'tolerance rate 2'
    Original Eqn: b'(wom_effectness_1+wom_effectness_2)/(ad_effectness_1+ad_effectness_2+wom_effectness_1+wom_effectness_2)'
    Units: b'person/contact'
    Limits: (None, None)
    Type: component

    b''
    """
    return (wom_effectness_1()+wom_effectness_2())/(ad_effectness_1()+ad_effectness_2()+wom_effectness_1()+wom_effectness_2())

@cache('step')
def market_rate_1():
    """
    Real Name: b'market rate 1 aka K1'
    Original Eqn: b'(ad_effectness_1+ad_effectness_2)/(ad_effectness_1+ad_effectness_2+wom_effectness_1+wom_effectness_2)'
    Units: b'person/contact'
    Limits: (None, None)
    Type: component

    b'aka K1'
    """
    return (ad_effectness_1()+ad_effectness_2())/(ad_effectness_1()+ad_effectness_2()+wom_effectness_1()+wom_effectness_2())

@cache('step')
def market_rate_2():
    """
    Real Name: b'market rate 2 aka K2'
    Original Eqn: b'(ad_effectness_1+ad_effectness_2)/(ad_effectness_1+ad_effectness_2+wom_effectness_1+wom_effectness_2)'
    Units: b'person/contact'
    Limits: (None, None)
    Type: component

    b'aka K2'
    """
    return (ad_effectness_1()+ad_effectness_2())/(ad_effectness_1()+ad_effectness_2()+wom_effectness_1()+wom_effectness_2())

@cache('run')
def wom_effectness_1():
    """
    Real Name: b'wom effectness 1'
    Original Eqn: b'0.015'
    Units: b'person/contact'
    Limits: (None, None)
    Type: constant

    b''
    """
    return 0.015

@cache('run')
def wom_effectness_2():
    """
    Real Name: b'wom effectness 2'
    Original Eqn: b'0.015'
    Units: b'person/contact'
    Limits: (None, None)
    Type: constant

    b''
    """
    return 0.015


@cache('run')
def ad_effectness_1():
    """
    Real Name: b'wom effectness 1'
    Original Eqn: b'0.011'
    Units: b'dmnl'
    Limits: (None, None)
    Type: constant

    b''
    """
    return 0.011

@cache('run')
def ad_effectness_2():
    """
    Real Name: b'wom effectness 2'
    Original Eqn: b'0.011'
    Units: b'dmnl'
    Limits: (None, None)
    Type: constant

    b''
    """
    return 0.011

@cache('run')
def contact_rate_1():
    """
    Real Name: b'contact rate 1'
    Original Eqn: b'100'
    Units: b'contact/person/Month'
    Limits: (None, None)
    Type: constant

    b''
    """
    return 100

@cache('run')
def contact_rate_2():
    """
    Real Name: b'contact rate 2'
    Original Eqn: b'100'
    Units: b'contact/person/Month'
    Limits: (None, None)
    Type: constant

    b''
    """
    return 100

@cache('run')
def neutral_rate_1():
    """
    Real Name: b'Neutral rate 1 aka P13'
    Original Eqn: b'0.2'
    Units: b'person/contact'
    Limits: (0, 1)
    Type: variable

    b'aka P13'
    """
    return 0.2

@cache('run')
def neutral_rate_2():
    """
    Real Name: b'Neutral rate 1 aka P23'
    Original Eqn: b'0.1'
    Units: b'person/contact'
    Limits: (0, 1)
    Type: variable

    b'aka P23'
    """
    return 0.1

@cache('run')
def chaotic_rate_1():
    """
    Real Name: b'Chaotic rate 1 aka P11'
    Original Eqn: b'0.3'
    Units: b'person/contact'
    Limits: (0, 1)
    Type: variable

    b'aka P11'
    """
    return 0.3

@cache('run')
def chaotic_rate_2():
    """
    Real Name: b'Chaotic rate 1 aka P21'
    Original Eqn: b'0.4'
    Units: b'person/contact'
    Limits: (0, 1)
    Type: variable

    b'aka P21'
    """
    return 0.4


@cache('run')
def total_population():
    """
    Real Name: b'total population'
    Original Eqn: b'10000'
    Units: b'person'
    Limits: (10000, 10000)
    Type: component

    b''
    """
    return 10000

@cache('step')
def adoption_from_wom_1():
    """
    Real Name: b'Adoption from WOM 1'
    Original Eqn: b'contact_rate_1 * adopters_1 * potential_adopters * wom_effectness_1 * P11 / total_population'
    Units: b'person/Month'
    Limits: (None, None)
    Type: component

    b''
    """
    return contact_rate_1() * adopters_1() * potential_adopters() * wom_effectness_1() * chaotic_rate_1() / total_population()

@cache('step')
def adoption_from_ad_1():
    """
    Real Name: b'Adoption from AD 1'
    Original Eqn: b'ad_effectness_1 * adopters'
    Units: b'person/Month'
    Limits: (None, None)
    Type: component

    b''
    """
    return ad_effectness_1()*potential_adopters()


@cache('step')
def adoption_from_wom_2():
    """
    Real Name: b'Adoption from WOM 2'
    Original Eqn: b'contact_rate_2 * adopters_2 * potential_adopters * wom_effectness_2 * P21 / total_population'
    Units: b'person/Month'
    Limits: (None, None)
    Type: component

    b''
    """
    return contact_rate_2() * adopters_2() * potential_adopters() * wom_effectness_2() * chaotic_rate_2() / total_population()

@cache('step')
def adoption_from_ad_2():
    """
    Real Name: b'Adoption from AD 2'
    Original Eqn: b'ad_effectness_2 * adopters'
    Units: b'person/Month'
    Limits: (None, None)
    Type: component

    b''
    """
    return ad_effectness_2()*potential_adopters()



@cache('run')
def final_time():
    """
    Real Name: b'FINAL TIME'
    Original Eqn: b'50'
    Units: b'Month'
    Limits: (None, None)
    Type: constant

    b'The final time for the simulation.'
    """
    return 50


@cache('run')
def initial_time():
    """
    Real Name: b'INITIAL TIME'
    Original Eqn: b'0'
    Units: b'Month'
    Limits: (None, None)
    Type: constant

    b'The initial time for the simulation.'
    """
    return 0


@cache('step')
def saveper():
    """
    Real Name: b'SAVEPER'
    Original Eqn: b'TIME STEP'
    Units: b'Month'
    Limits: (None, None)
    Type: component

    b'The frequency with which output is stored.'
    """
    return time_step()


@cache('run')
def time_step():
    """
    Real Name: b'TIME STEP'
    Original Eqn: b'1'
    Units: b'Month'
    Limits: (None, None)
    Type: constant

    b'The time step for the simulation.'
    """
    return 1


_integ_adopters1 = functions.Integ(lambda: adoption_rate_1() + competitive_rate_1()  
                                   - reverse_rate_1() - competitive_rate_2(), lambda: 0)

_integ_adopters2 = functions.Integ(lambda: adoption_rate_2() + competitive_rate_2() 
                                   - reverse_rate_2() - competitive_rate_1(), lambda: 0)

_integ_potential_adopters = functions.Integ(lambda: 
                                            - adoption_rate_1() - adoption_rate_2() 
                                            + reverse_rate_1() + reverse_rate_2(), lambda: total_population())
